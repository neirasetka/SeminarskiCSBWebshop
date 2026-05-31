using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    public class TransactionsController : BaseCRUDController<Transaction, TransactionSearchRequest, TransactionUpsertRequest, TransactionUpsertRequest>
    {
        public TransactionsController(ICRUDService<Transaction, TransactionSearchRequest, TransactionUpsertRequest, TransactionUpsertRequest> service) : base(service)
        {
        }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<Transaction>> Get([FromQuery] TransactionSearchRequest search)
        {
            return await base.Get(search);
        }

        [HttpGet("{ID:int}")]
        [Authorize(Roles = "Admin")]
        public override async Task<Transaction> GetById(int ID)
        {
            return await base.GetById(ID);
        }
    }
}
