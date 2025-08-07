using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class OrdersService : CRUDService<Order, OrderSearchRequest, Orders, OrderUpsertRequest, OrderUpsertRequest>, IOrderService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;

        public OrdersService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public override async Task<List<Order>> Get(OrderSearchRequest request)
        {
            var query = _context.Orders.
               Include(z => z.User)
               .AsQueryable();

            if (!string.IsNullOrWhiteSpace(request?.OrderNumber))
            {
                query = query.Where(x => x.OrderNumber.StartsWith(request.OrderNumber));
            }

            var list = query.ToList();

            List<Orders> result = new List<Orders>();

            foreach (var item in list)
            {
                Orders newList = new Orders();

                newList.OrderNumber = item.OrderNumber;
                newList.Date = item.Date;
                newList.Price = item.Price;
                newList.UserID = item.User.UserID;
                newList.OrderID = item.OrderID;

                result.Add(newList);
            }

            return _mapper.Map<List<Order>>(result);
        }

        public override async Task<Order> Insert(OrderUpsertRequest request)
        {
            var entity = _mapper.Map<Orders>(request);

            _context.Set<Orders>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<Order>(entity);
        }

        public override async Task<Order> Update(int ID, OrderUpsertRequest request)
        {

            var entity = _context.Set<Orders>().Find(ID);
            _context.Set<Orders>().Attach(entity);
            _context.Set<Orders>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<Order>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var orders = await _context.Orders.Where(c => c.OrderID == ID).FirstOrDefaultAsync();

            if (orders != null)
            {
                await _context.SaveChangesAsync();

                _context.Orders.Remove(orders);
                await _context.SaveChangesAsync();

                return true;
            }
            return false;
        }

        public Order GetByOrderNumber(string orderNumber)
        {
            var entity = _context.Orders.Where(n => n.OrderNumber.Contains(orderNumber)).FirstOrDefault();

            if (entity == null)
            {
                throw new Exception("Order already exists!");
            }
            return _mapper.Map<Order>(entity);
        }
    }
}
