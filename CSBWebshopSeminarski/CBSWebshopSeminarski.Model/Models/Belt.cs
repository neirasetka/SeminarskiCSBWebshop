namespace CBSWebshopSeminarski.Model.Models
{
    public class Belt
    {
        public int BeltID { get; set; }
        public string BeltName { get; set; } = null!;
        public string Code { get; set; } = null!;
        public float Price { get; set; }
        public string Description { get; set; } = null!;
        public byte[] Image { get; set; } = null!;
        public int BeltTypeID { get; set; }
        public BeltType BeltType { get; set; } = null!;
        public int UserID { get; set; }
        public User Users { get; set; } = null!;
    }
}
