namespace CBSWebshopSeminarski.Model.Models
{
    public class Belt
    {
        public int BeltID { get; set; }
        public string BeltName { get; set; }
        public string Code { get; set; }
        public float Price { get; set; }
        public string Description { get; set; }
        public byte[] Image { get; set; }
        public int BeltTypeID { get; set; }
        public BeltType BeltType { get; set; }
        public int UserID { get; set; }
        public User Users { get; set; }
    }
}
