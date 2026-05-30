namespace CBSWebshopSeminarski.Model
{
    public static class ValidationPatterns
    {
        public const string Phone = @"^[\+]?[\d\s\-\(\)]{6,20}$";
        public const string PhoneErrorMessage = "Please enter a valid phone number.";
    }
}
