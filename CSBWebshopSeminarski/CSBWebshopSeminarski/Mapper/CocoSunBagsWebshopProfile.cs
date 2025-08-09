using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;
using Transaction = CBSWebshopSeminarski.Model.Models.Transaction;

namespace CSBWebshopSeminarski.Mapper
{
    public class CocoSunBagsWebshopProfile : Profile
    {
        public CocoSunBagsWebshopProfile()
        {
            CreateMap<BagTypes, BagType>();
            CreateMap<BagTypes, BagTypeSearchRequest>().ReverseMap();
            CreateMap<BagTypes, BagTypeUpsertRequest>().ReverseMap();

            CreateMap<BeltTypes, BeltType>();
            CreateMap<BeltTypes, BeltTypeSearchRequest>().ReverseMap();
            CreateMap<BeltTypes, BeltTypeUpsertRequest>().ReverseMap();

            CreateMap<Users, User>()
                .ForMember(d => d.UserRole, o => o.MapFrom(s => s.UserRoles));
            CreateMap<Users, UserUpsertRequest>().ReverseMap();

            CreateMap<UserRoles, UserRole>()
                .ForMember(d => d.Role, o => o.MapFrom(s => s.Roles));

            CreateMap<Bags, Bag>().ReverseMap();
            CreateMap<Bags, BagUpsertRequest>().ReverseMap();

            CreateMap<Belts, Belt>().ReverseMap();
            CreateMap<Belts, BeltUpsertRequest>().ReverseMap();

            CreateMap<Orders, Order>();
            CreateMap<Orders, OrderUpsertRequest>().ReverseMap();

            CreateMap<OrderItems, OrderItem>().ReverseMap();
            CreateMap<OrderItems, OrderItemUpsertRequest>().ReverseMap();

            CreateMap<Roles, Role>();

            CreateMap<Transactions, Transaction>();
            CreateMap<Transactions, TransactionUpsertRequest>().ReverseMap();

            CreateMap<Reviews, Review>();
            CreateMap<Reviews, ReviewUpsertRequest>().ReverseMap();

            CreateMap<Rates, Rate>();
            CreateMap<Rates, RateUpsertRequest>().ReverseMap();

            CreateMap<Purchases, Purchase>();
            CreateMap<Purchases, PurchaseUpsertRequest>().ReverseMap();

            CreateMap<Favorites, Favorite>();
            CreateMap<Favorites, FavoriteUpsertRequest>().ReverseMap();
        }
    }
}
