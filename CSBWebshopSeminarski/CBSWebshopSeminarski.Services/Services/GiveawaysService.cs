using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.Security.Cryptography;

namespace CBSWebshopSeminarski.Services.Services
{
    public class AnnounceWinnerResult
    {
        public bool Success { get; set; }
        public string? WinnerName { get; set; }
        public string? WinnerEmail { get; set; }
        public int SubscribersNotified { get; set; }
        public int? NewsItemId { get; set; }
        public string? ErrorMessage { get; set; }
    }

    public class GiveawaysService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly EmailService _emailService;

        public GiveawaysService(CocoSunBagsWebshopDbContext context, EmailService emailService)
        {
            _context = context;
            _emailService = emailService;
        }

        public async Task<Giveaways> CreateGiveawayAsync(string title, DateTime startDate, DateTime endDate)
        {
            if (string.IsNullOrWhiteSpace(title))
            {
                throw new ArgumentException("Title is required", nameof(title));
            }
            //Normalize to UTC
            var startUtc = DateTime.SpecifyKind(startDate, DateTimeKind.Utc).ToUniversalTime();
            var endUtc = DateTime.SpecifyKind(endDate, DateTimeKind.Utc).ToUniversalTime();

            if (endUtc <= startUtc)
            {
                throw new ArgumentException("EndDate must be after StartDate");
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

        public async Task<Participants> RegisterParticipantAsync(int giveawayId, string name, string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new ArgumentException("Email is required", nameof(email));
            }
            if (email.Length > 254)
            {
                throw new ArgumentException("Email too long", nameof(email));
            }
            try
            {
                var _ = new EmailAddressAttribute().IsValid(email) ? true : throw new ArgumentException("Invalid email format", nameof(email));
            }
            catch
            {
                throw new ArgumentException("Invalid email format", nameof(email));
            }

            var normalizedEmail = email.Trim().ToLowerInvariant();

            var giveaway = await _context.Giveaways.FindAsync(giveawayId)
                           ?? throw new InvalidOperationException("Giveaway not found");
            var now = DateTime.UtcNow;
            if (now < giveaway.StartDate || now > giveaway.EndDate || giveaway.IsClosed)
            {
                throw new InvalidOperationException("Giveaway is not accepting entries");
            }
            var alreadyExists = await _context.Participants.AnyAsync(p => p.GiveawayId == giveawayId && p.Email == normalizedEmail);
            if (alreadyExists)
            {
                throw new InvalidOperationException("Participant with this email already registered for this giveaway");
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
                           ?? throw new InvalidOperationException("Giveaway not found");
            if (DateTime.UtcNow < giveaway.EndDate)
            {
                throw new InvalidOperationException("Giveaway has not ended yet");
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

        public async Task NotifyWinnerAsync(Participants winner)
        {
            if (!string.IsNullOrWhiteSpace(winner.Email))
            {
                await _emailService.SendEmailAsync(winner.Email, "Congratulations, You Are a Winner!", "You have won the giveaway!");
            }
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
                    ?? throw new InvalidOperationException("Giveaway not found");

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
                    throw new InvalidOperationException("Giveaway has not ended yet");
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
                    await _emailService.SendEmailAsync(
                        winner.Email,
                        $"Čestitamo! Pobjednik ste giveaway-a \"{giveaway.Title}\"!",
                        $"Dragi/a {winnerDisplayName},\n\n" +
                        $"Sa zadovoljstvom Vam javljamo da ste izabrani kao pobjednik našeg giveaway-a \"{giveaway.Title}\"!\n\n" +
                        $"Uskoro ćemo Vas kontaktirati sa detaljima o preuzimanju nagrade.\n\n" +
                        $"Hvala što ste dio naše zajednice!\n\n" +
                        $"S poštovanjem,\nVaš CocoSunBags tim"
                    );
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
                    await _emailService.SendEmailAsync(
                        subscriber.Email,
                        $"Pobjednik giveaway-a \"{giveaway.Title}\" je izabran!",
                        $"Poštovani,\n\n" +
                        $"Imamo pobjednika! Giveaway \"{giveaway.Title}\" je završen, a sretni pobjednik je {winnerDisplayName}.\n\n" +
                        $"Čestitamo pobjedniku i hvala svima na učešću!\n\n" +
                        $"Pratite nas za nove giveaway-e i uzbudljive prilike.\n\n" +
                        $"S poštovanjem,\nVaš CocoSunBags tim"
                    );
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
