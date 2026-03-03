namespace CSBWebshopSeminarski.Core.Entities
{
    public class Favorites
    {
        public int FavoriteID { get; set; }
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        public int UserID { get; set; }
        public virtual Users User { get; set; } = null!;
        public virtual Bags Bag { get; set; } = null!;
        public virtual Belts Belt { get; set; } = null!;
    }
}
