# SeminarskiCSBWebshop

## CSB Webshop — Starting the app

### Docker
Run the following commands in the directory where the project is located:

```bash
docker-compose build
docker-compose up
```

### Desktop user (Windows)
  - username: admin
  - password: Admin123!
 
  - username: buyer
  - password: Buyer123!
    
- Starting the app:

If you want to start desktop application using dart define
flutter run --dart-define=baseUrl=http://10.0.2.2:8080/api -d windows

### Mobile user
  - username: buyer
  - password: Buyer123!
 
  - username: admin
  - password: Admin123!
 
  These are default mobile users. You can create your own by clicking register button.
  
- Starting the app:

```bash
flutter pub get
flutter emulators --launch Medium_Phone_API_36.1
flutter run
```
If you want to start application using dart define
flutter run --dart-define=baseUrl=http://10.0.2.2:8080/api

### Test credit card(Stripe Test mode)
- Card number: **4242 4242 4242 4242**
- Expiry date: any future date (for example: 12/34)
- CVC: any 3 numbers
