using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;

namespace CSBWebshopSeminarski.Controllers
{
    public class TransactionsController : BaseCRUDController<Transaction, TransactionSearchRequest, TransactionUpsertRequest, TransactionUpsertRequest>
    {
        public TransactionsController(ICRUDService<Transaction, TransactionSearchRequest, TransactionUpsertRequest, TransactionUpsertRequest> service) : base(service)
        {
        }
    }
}
