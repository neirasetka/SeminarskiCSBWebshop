using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

using CBSWebshopSeminarski.Services.Exceptions;

namespace CBSWebshopSeminarski.Services.Services
{
    public class TransactionsService : CRUDService<Transaction, TransactionSearchRequest, Transactions, TransactionUpsertRequest, TransactionUpsertRequest>
    {
        private new readonly CocoSunBagsWebshopDbContext _context;
        private new readonly IMapper _mapper;
        public TransactionsService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public override async Task<PagedResult<Transaction>> Get(TransactionSearchRequest request)
        {
            var query = _context.Transactions.Include(n => n.Order).AsQueryable();

            if (request.UserID != 0)
            {
                query = query.Where(i => i.UserID == request.UserID);
            }
            if (request.OrderID != 0)
            {
                query = query.Where(i => i.OrderID == request.OrderID);
            }
            if (!string.IsNullOrWhiteSpace(request.OrderNumber))
            {
                query = query.Where(i => i.OrderNumber == request.OrderNumber);
            }
            if (request.From != null)
            {
                query = query.Where(i => i.TransactionDate >= request.From);
            }
            if (request.To != null)
            {
                query = query.Where(i => i.TransactionDate <= request.To);
            }

            query = query.OrderBy(c => c.TransactionDate);

            return await ToPagedResultAsync(query, request);
        }

        public override async Task<Transaction> GetById(int ID)
        {
            var entity = await _context.Transactions
                .Where(i => i.TransactionID == ID)
                .SingleOrDefaultAsync();

            return _mapper.Map<Transaction>(entity);
        }

        public override async Task<Transaction> Insert(TransactionUpsertRequest request)
        {
            var entity = _mapper.Map<Transactions>(request);

            _context.Set<Transactions>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<Transaction>(entity);
        }

        public override async Task<Transaction> Update(int ID, TransactionUpsertRequest request)
        {
            var entity = _context.Set<Transactions>().Find(ID);
            if (entity == null)
                throw new NotFoundException($"Transaction with ID {ID} not found.");

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<Transaction>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var transaction = await _context.Transactions.Where(i => i.TransactionID == ID).FirstOrDefaultAsync();
            if (transaction != null)
            {
                _context.Transactions.Remove(transaction);
                await _context.SaveChangesAsync();

                return true;
            }
            return false;
        }
    }
}
