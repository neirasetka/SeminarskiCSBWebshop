namespace CBSWebshopSeminarski.Model.Models
{
    public class Favorite
    {
        public int FavoriteID { get; set; }
        public int UserID { get; set; }
        public virtual User User { get; set; } = null!;
        public int? BagID { get; set; }
        public int? BeltID { get; set; }
        public virtual Bag Bag { get; set; } = null!;
        public virtual Belt Belt { get; set; } = null!;
    }
}
