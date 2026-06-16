using CBSWebshopSeminarski.Model;
using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.Security.Cryptography;

using CBSWebshopSeminarski.Services.Exceptions;
using ValidationException = CBSWebshopSeminarski.Services.Exceptions.ValidationException;

namespace CBSWebshopSeminarski.Services.Services
{
    public class GiveawaysService : IGiveawaysService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly RabbitMqMailPublisher _mailPublisher;

        public GiveawaysService(CocoSunBagsWebshopDbContext context, RabbitMqMailPublisher mailPublisher)
        {
            _context = context;
            _mailPublisher = mailPublisher;
        }

        public async Task<PagedResult<GiveawayDto>> GetAllAsync(GiveawaySearchRequest search)
        {
            search ??= new GiveawaySearchRequest();
            var now = DateTime.UtcNow;
            var query = _context.Giveaways.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Status))
            {
                switch (search.Status.Trim().ToLowerInvariant())
                {
                    case "active":
                        query = query.Where(g => !g.IsClosed && g.StartDate <= now && g.EndDate >= now);
                        break;
                    case "closed":
                        query = query.Where(g => g.IsClosed || g.EndDate < now);
                        break;
                    case "all":
                        break;
                    default:
                        throw new ValidationException(ValidationMessages.GiveawayStatusFilterValues);
                }
            }

            var projected = query
                .OrderByDescending(g => g.StartDate)
                .Select(g => new GiveawayDto
                {
                    Id = g.Id,
                    Title = g.Title,
                    StartDate = g.StartDate,
                    EndDate = g.EndDate,
                    IsClosed = g.IsClosed,
                    WinnerParticipantId = g.WinnerParticipantId
                });

            var (page, pageSize) = PaginationHelper.Normalize(search);
            var totalCount = await projected.CountAsync();
            var items = await projected
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<GiveawayDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<GiveawayDto?> GetByIdAsync(int id)
        {
            var giveaway = await _context.Giveaways.FindAsync(id);
            if (giveaway == null)
                return null;

            return MapToDto(giveaway);
        }

        public async Task<PagedResult<ParticipantDto>> GetParticipantsAsync(int giveawayId, PagedSearchRequest search)
        {
            search ??= new PagedSearchRequest();
            var query = _context.Participants
                .Where(p => p.GiveawayId == giveawayId)
                .OrderByDescending(p => p.EntryDate)
                .Select(p => new ParticipantDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    Email = p.Email,
                    EntryDate = p.EntryDate,
                    GiveawayId = p.GiveawayId
                });

            var (page, pageSize) = PaginationHelper.Normalize(search);
            var totalCount = await query.CountAsync();
            var items = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<ParticipantDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        private static GiveawayDto MapToDto(Giveaways g) =>
            new()
            {
                Id = g.Id,
                Title = g.Title,
                StartDate = g.StartDate,
                EndDate = g.EndDate,
                IsClosed = g.IsClosed,
                WinnerParticipantId = g.WinnerParticipantId
            };

        public async Task<Giveaways> CreateGiveawayAsync(string title, DateTime startDate, DateTime endDate)
        {
            if (string.IsNullOrWhiteSpace(title))
            {
                throw new ValidationException(ValidationMessages.TitleRequired);
            }
            //Normalize to UTC
            var startUtc = DateTime.SpecifyKind(startDate, DateTimeKind.Utc).ToUniversalTime();
            var endUtc = DateTime.SpecifyKind(endDate, DateTimeKind.Utc).ToUniversalTime();

            if (endUtc <= startUtc)
            {
                throw new ValidationException("Datum kraja mora biti nakon datuma početka.");
            }
            var giveaway = new Giveaways
            {
                Title = title.Trim(),
                StartDate = startUtc,
                EndDate = endUtc,
                IsClosed = false
            };

            _context.Giveaways.Add(giveaway);
            await _context.SaveChangesAsync();

            return giveaway;
        }

        public async Task<Giveaways> UpdateGiveawayDurationAsync(int giveawayId, DateTime startDate, DateTime endDate)
        {
            var giveaway = await _context.Giveaways.FindAsync(giveawayId)
                           ?? throw new NotFoundException("Giveaway not found");

            if (giveaway.IsClosed || giveaway.WinnerParticipantId.HasValue)
            {
                throw new BusinessException("Nije moguće mijenjati trajanje zatvorenog giveawaya.");
            }

            // Normalize to UTC
            var startUtc = DateTime.SpecifyKind(startDate, DateTimeKind.Utc).ToUniversalTime();
            var endUtc = DateTime.SpecifyKind(endDate, DateTimeKind.Utc).ToUniversalTime();

            if (endUtc <= startUtc)
            {
                throw new ValidationException("Datum kraja mora biti nakon datuma početka.");
            }

            giveaway.StartDate = startUtc;
            giveaway.EndDate = endUtc;

            await _context.SaveChangesAsync();
            return giveaway;
        }

        public async Task<Participants> RegisterParticipantAsync(int giveawayId, string name, string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new ValidationException(ValidationMessages.EmailRequired);
            }
            if (email.Length > 254)
            {
                throw new ValidationException("Email može imati najviše 254 znaka.");
            }
            try
            {
                var _ = new EmailAddressAttribute().IsValid(email) ? true : throw new ValidationException(ValidationMessages.EmailInvalid);
            }
            catch
            {
                throw new ValidationException(ValidationMessages.EmailInvalid);
            }

            var normalizedEmail = email.Trim().ToLowerInvariant();

            var giveaway = await _context.Giveaways.FindAsync(giveawayId)
                           ?? throw new NotFoundException("Giveaway not found");
            var now = DateTime.UtcNow;
            if (now < giveaway.StartDate || now > giveaway.EndDate || giveaway.IsClosed)
            {
                throw new BusinessException("Giveaway is not accepting entries");
            }
            var alreadyExists = await _context.Participants.AnyAsync(p => p.GiveawayId == giveawayId && p.Email == normalizedEmail);
            if (alreadyExists)
            {
                throw new ConflictException("Već učestvujete u giveawayu.");
            }

            var participant = new Participants
            {
                Name = string.IsNullOrWhiteSpace(name) ? null : name.Trim(),
                Email = normalizedEmail,
                GiveawayId = giveawayId,
                EntryDate = DateTime.UtcNow
            };

            _context.Participants.Add(participant);
            await _context.SaveChangesAsync();

            return participant;
        }

        public async Task<Participants?> SelectRandomWinnerAsync(int giveawayId)
        {
            var giveaway = await _context.Giveaways.FindAsync(giveawayId)
                           ?? throw new NotFoundException("Giveaway not found");
            if (DateTime.UtcNow < giveaway.EndDate)
            {
                throw new BusinessException("Giveaway has not ended yet");
            }
            var participants = await _context.Participants
                                             .Where(p => p.GiveawayId == giveawayId)
                                             .ToListAsync();
            if (participants.Count == 0)
            {
                return null;
            }

            var index = RandomNumberGenerator.GetInt32(participants.Count);
            return participants[index];
        }

        public Task NotifyWinnerAsync(Participants winner)
        {
            if (!string.IsNullOrWhiteSpace(winner.Email))
            {
                var winnerDisplayName = !string.IsNullOrWhiteSpace(winner.Name) ? winner.Name : "Dragi korisniče";
                _mailPublisher.Publish(
                    sender: "no-reply@cocosunbags.local",
                    recipient: winner.Email,
                    subject: "Čestitamo! Osvojili ste giveaway",
                    content: $"{winnerDisplayName},\n\n" +
                             "Čestitamo, osvojili ste torbicu kod CocoSunBags u našem darivanju!\n\n" +
                             "Uskoro ćemo Vas kontaktirati sa svim detaljima.\n\n" +
                             "Srdačan pozdrav,\nCocoSunBags tim");
            }

            return Task.CompletedTask;
        }

        public async Task<Participants> NotifyWinnerForGiveawayAsync(int giveawayId)
        {
            var giveaway = await _context.Giveaways.FindAsync(giveawayId)
                ?? throw new NotFoundException("Winner not found for this giveaway");

            if (!giveaway.WinnerParticipantId.HasValue)
                throw new NotFoundException("Winner not found for this giveaway");

            var winner = await _context.Participants.FindAsync(giveaway.WinnerParticipantId.Value)
                ?? throw new NotFoundException("Winner not found");

            await NotifyWinnerAsync(winner);
            return winner;
        }

        public async Task<Participants?> DrawAndPersistWinnerAsync(int giveawayId)
        {
            const int maxRetries = 3;
            int attempt = 0;
            while (true)
            {
                attempt++;
                using var tx = await _context.Database.BeginTransactionAsync();

                var giveaway = await _context.Giveaways
                    .Include(g => g.Participants)
                    .FirstOrDefaultAsync(g => g.Id == giveawayId)
                    ?? throw new NotFoundException("Giveaway not found");

                if (giveaway.IsClosed)
                {
                    if (giveaway.WinnerParticipantId.HasValue)
                    {
                        var existingWinner = await _context.Participants.FindAsync(giveaway.WinnerParticipantId.Value);
                        await tx.CommitAsync();
                        return existingWinner;
                    }
                    await tx.CommitAsync();
                    return null;
                }

                if (DateTime.UtcNow < giveaway.EndDate)
                {
                    await tx.RollbackAsync();
                    throw new BusinessException("Giveaway has not ended yet");
                }

                var participants = giveaway.Participants.ToList();
                if (participants.Count == 0)
                {
                    giveaway.IsClosed = true;
                    try
                    {
                        await _context.SaveChangesAsync();
                        await tx.CommitAsync();
                        return null;
                    }
                    catch (DbUpdateConcurrencyException) when (attempt < maxRetries)
                    {
                        await tx.RollbackAsync();
                        _context.ChangeTracker.Clear();
                        continue;
                    }
                }

                var winner = participants[RandomNumberGenerator.GetInt32(participants.Count)];

                giveaway.WinnerParticipantId = winner.Id;
                giveaway.IsClosed = true;

                try
                {
                    await _context.SaveChangesAsync();
                    await tx.CommitAsync();
                    return winner;
                }
                catch (DbUpdateConcurrencyException) when (attempt < maxRetries)
                {
                    await tx.RollbackAsync();
                    _context.ChangeTracker.Clear();
                    continue;
                }
            }
        }

        ///Announces the giveaway winner by:
        ///1. Creating a news item on the info panel
        ///2. Sending email to the winner
        ///3. Sending email to all giveaway newsletter subscribers
        public async Task<AnnounceWinnerResult> AnnounceWinnerAsync(int giveawayId, string? initiatedBy = null)
        {
            var giveaway = await _context.Giveaways
                .Include(g => g.WinnerParticipant)
                .FirstOrDefaultAsync(g => g.Id == giveawayId);

            if (giveaway == null)
            {
                return new AnnounceWinnerResult
                {
                    Success = false,
                    ErrorMessage = "Giveaway not found"
                };
            }

            if (!giveaway.WinnerParticipantId.HasValue || giveaway.WinnerParticipant == null)
            {
                return new AnnounceWinnerResult
                {
                    Success = false,
                    ErrorMessage = "No winner has been selected for this giveaway. Please draw a winner first."
                };
            }

            var winner = giveaway.WinnerParticipant;
            var winnerDisplayName = !string.IsNullOrWhiteSpace(winner.Name) ? winner.Name : "Sretni pobjednik";

            //1. Create news item for info panel
            var newsItem = new NewsItem
            {
                PublishedAtUtc = DateTime.UtcNow,
                Title = $"Pobjednik giveaway-a: {giveaway.Title}",
                Body = $"Čestitamo! Pobjednik našeg giveaway-a \"{giveaway.Title}\" je {winnerDisplayName}! " +
                       $"Hvala svima na učešću. Pratite nas za nove prilike!",
                Segment = "GiveawaySubscribers",
                CreatedBy = initiatedBy
            };

            _context.News.Add(newsItem);
            await _context.SaveChangesAsync();

            //2. Send email to winner
            if (!string.IsNullOrWhiteSpace(winner.Email))
            {
                try
                {
                    _mailPublisher.Publish(
                        sender: "no-reply@cocosunbags.local",
                        recipient: winner.Email,
                        subject: $"Čestitamo! Pobjednik ste giveaway-a \"{giveaway.Title}\"!",
                        content: $"Dragi/a {winnerDisplayName},\n\n" +
                                 $"Sa zadovoljstvom Vam javljamo da ste izabrani kao pobjednik našeg giveaway-a \"{giveaway.Title}\"!\n\n" +
                                 $"Uskoro ćemo Vas kontaktirati sa detaljima o preuzimanju nagrade.\n\n" +
                                 $"Hvala što ste dio naše zajednice!\n\n" +
                                 $"S poštovanjem,\nVaš CocoSunBags tim");
                }
                catch
                {
                    //Log but don't fail the entire operation
                }
            }

            //3. Send email to all giveaway newsletter subscribers
            int subscribersNotified = 0;
            var subscribers = await _context.Subscribers
                .Where(s => s.IsSubscribedToGiveaway)
                .ToListAsync();

            foreach (var subscriber in subscribers)
            {
                //Don't send duplicate to winner if they're also a subscriber
                if (subscriber.Email.Equals(winner.Email, StringComparison.OrdinalIgnoreCase))
                    continue;

                try
                {
                    _mailPublisher.Publish(
                        sender: "no-reply@cocosunbags.local",
                        recipient: subscriber.Email,
                        subject: $"Pobjednik giveaway-a \"{giveaway.Title}\" je izabran!",
                        content: $"Poštovani,\n\n" +
                                 $"Imamo pobjednika! Giveaway \"{giveaway.Title}\" je završen, a sretni pobjednik je {winnerDisplayName}.\n\n" +
                                 $"Čestitamo pobjedniku i hvala svima na učešću!\n\n" +
                                 $"Pratite nas za nove giveaway-e i uzbudljive prilike.\n\n" +
                                 $"S poštovanjem,\nVaš CocoSunBags tim");
                    subscribersNotified++;
                }
                catch
                {
                    //Log but continue with other subscribers
                }
            }

            return new AnnounceWinnerResult
            {
                Success = true,
                WinnerName = winnerDisplayName,
                WinnerEmail = winner.Email,
                SubscribersNotified = subscribersNotified,
                NewsItemId = newsItem.Id
            };
        }
    }
}
