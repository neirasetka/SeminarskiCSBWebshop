using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
public class TransactionsService : CRUDService<Transaction, TransactionSearchRequest, Transactions, TransactionUpsertRequest, TransactionUpsertRequest>
{
    private readonly CocoSunBagsWebshopDbContext _context;
    private readonly IMapper _mapper;
    public TransactionsService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
    {
        _context = context;
        _mapper = mapper;
    }
    public override async Task<List<Transaction>> Get(TransactionSearchRequest request)
        {
            var query = _context.Transactions.Include(n => n.Order).AsQueryable().OrderBy(c => c.TransactionDate);

            if (request.UserID != 0)
            {
                query = (IOrderedQueryable<Transactions>)query.Where(i => i.UserID == request.UserID);
            }
            if (request.From != null)
            {
                query = (IOrderedQueryable<Transactions>)query.Where(i => i.TransactionDate >= request.From);
            }
            if (request.To != null)
            {
                query = (IOrderedQueryable<Transactions>)query.Where(i => i.TransactionDate <= request.To);
            }

            var list = await query.ToListAsync();

            return _mapper.Map<List<Transaction>>(list);
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
            _context.Set<Transactions>().Attach(entity);
            _context.Set<Transactions>().Update(entity);

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
