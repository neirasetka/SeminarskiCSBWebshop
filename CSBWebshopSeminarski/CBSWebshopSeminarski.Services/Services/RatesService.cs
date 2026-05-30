using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using BagOrBeltReferenceValidator = CBSWebshopSeminarski.Services.BagOrBeltReferenceValidator;

using CBSWebshopSeminarski.Services.Exceptions;

namespace CBSWebshopSeminarski.Services.Services
{
    public class RatesService : IRatesService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        public RatesService(CocoSunBagsWebshopDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<PagedResult<Rate>> Get(RateSearchRequest search)
        {
            search ??= new RateSearchRequest();
            var query = _context.Rates.AsQueryable();

            if (search.UserID != 0)
            {
                query = query.Where(i => i.UserID == search.UserID);
            }

            if (search.BagID.HasValue)
            {
                query = query.Where(i => i.BagID == search.BagID);
            }

            if (search.BeltID.HasValue)
            {
                query = query.Where(i => i.BeltID == search.BeltID);
            }

            if (search.Rating != 0)
            {
                query = query.Where(i => i.Rating == search.Rating);
            }

            return await PagedQueryHelper.ToPagedResultAsync<Rates, Rate>(query, search, _mapper);
        }

        public async Task<Rate> GetById(int ID)
        {
            var entity = await _context.Rates
               .Where(i => i.RateID == ID)
               .SingleOrDefaultAsync();

            return _mapper.Map<Rate>(entity);
        }

        public async Task<Rate> Insert(RateUpsertRequest request)
        {
            BagOrBeltReferenceValidator.ValidateExactlyOne(request.BagID, request.BeltID, "Rate");
            var (bagId, beltId) = BagOrBeltReferenceValidator.Normalize(request.BagID, request.BeltID);
            request.BagID = bagId;
            request.BeltID = beltId;

            var entity = _mapper.Map<Rates>(request);
            _context.Set<Rates>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<Rate>(entity);
        }

        public async Task<Rate> Update(int ID, RateUpsertRequest request)
        {
            BagOrBeltReferenceValidator.ValidateExactlyOne(request.BagID, request.BeltID, "Rate");
            var (bagId, beltId) = BagOrBeltReferenceValidator.Normalize(request.BagID, request.BeltID);
            request.BagID = bagId;
            request.BeltID = beltId;

            var entity = _context.Set<Rates>().Find(ID);
            if (entity == null)
                throw new NotFoundException($"Rate with ID {ID} not found.");
            var ownerUserId = entity.UserID;
            _context.Set<Rates>().Attach(entity);
            _context.Set<Rates>().Update(entity);

            _mapper.Map(request, entity);
            entity.UserID = ownerUserId;

            await _context.SaveChangesAsync();

            return _mapper.Map<Rate>(entity);
        }

        public async Task<bool> Delete(int ID)
        {
            var rate = await _context.Rates.Where(i => i.RateID == ID).FirstOrDefaultAsync();
            if (rate != null)
            {
                _context.Rates.Remove(rate);
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }
    }
}
