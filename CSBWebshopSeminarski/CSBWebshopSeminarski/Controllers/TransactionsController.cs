using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class TransactionsController : BaseCRUDController<Transaction, TransactionSearchRequest, TransactionUpsertRequest, TransactionUpsertRequest>
    {
        public TransactionsController(ICRUDService<Transaction, TransactionSearchRequest, TransactionUpsertRequest, TransactionUpsertRequest> service) : base(service)
        {
        }
    }
}
