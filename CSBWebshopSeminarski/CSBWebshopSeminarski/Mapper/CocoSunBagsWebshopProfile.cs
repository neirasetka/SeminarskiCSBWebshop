using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Core.Entities;
using OccasionEntity = CSBWebshopSeminarski.Core.Entities.OccasionType;
using OccasionModel = CBSWebshopSeminarski.Model.Models.OccasionType;
using SeasonEntity = CSBWebshopSeminarski.Core.Entities.SeasonType;
using SeasonModel = CBSWebshopSeminarski.Model.Models.SeasonType;
using ShippingStatusEntity = CSBWebshopSeminarski.Core.Entities.ShippingStatus;
using ShippingStatusModel = CBSWebshopSeminarski.Model.Models.ShippingStatus;
using StyleEntity = CSBWebshopSeminarski.Core.Entities.StyleType;
using StyleModel = CBSWebshopSeminarski.Model.Models.StyleType;
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

            CreateMap<Orders, Order>()
                .ForMember(d => d.PaymentStatus, o => o.MapFrom(s => s.PaymentStatus.ToString()));
            CreateMap<Orders, OrderUpsertRequest>().ReverseMap();
            CreateMap<TrackingEvents, TrackingEvent>().ReverseMap();
            CreateMap<Orders, ShippingInfo>()
                .ForMember(d => d.TrackingEvents, o => o.Ignore());

            // Shipping mappings
            CreateMap<ShippingStatusEntity, ShippingStatusModel>()
                .ConvertUsing(src => (ShippingStatusModel)src);
            CreateMap<ShippingStatusModel, ShippingStatusEntity>()
                .ConvertUsing(src => (ShippingStatusEntity)src);

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

            CreateMap<LookbookItems, LookbookItem>().ReverseMap();
            CreateMap<LookbookItems, LookbookUpsertRequest>().ReverseMap();

            CreateMap<OccasionEntity, OccasionModel>()
                .ConvertUsing(src => (OccasionModel)src);
            CreateMap<OccasionModel, OccasionEntity>()
                .ConvertUsing(src => (OccasionEntity)src);

            CreateMap<StyleEntity, StyleModel>()
                .ConvertUsing(src => (StyleModel)src);
            CreateMap<StyleModel, StyleEntity>()
                .ConvertUsing(src => (StyleEntity)src);

            CreateMap<SeasonEntity, SeasonModel>()
                .ConvertUsing(src => (SeasonModel)src);
            CreateMap<SeasonModel, SeasonEntity>()
                .ConvertUsing(src => (SeasonEntity)src);
        }
    }
}
