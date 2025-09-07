using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class BagsListVM
    {
        public int BagID { get; set; }
        public string BagName { get; set; }
        public string Code { get; set; }
        public float Price { get; set; }
        public string Description { get; set; }
        public byte[] Image { get; set; }
        public int BagTypeID { get; set; }
        public BagType BagType { get; set; }
    }
}
