using CBSWebshopSeminarski.Model.Models;

namespace CBSWebshopSeminarski.Model.ViewModels
{
    public class BagsListVM
    {
        public int BagID { get; set; }
        public string BagName { get; set; } = null!;
        public string Code { get; set; } = null!;
        public float Price { get; set; }
        public string Description { get; set; } = null!;
        public byte[] Image { get; set; } = null!;
        public int BagTypeID { get; set; }
        public BagType BagType { get; set; } = null!;
    }
}
