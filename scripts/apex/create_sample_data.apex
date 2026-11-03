// Sample Data Seeding for FoodHub Restaurant Management System

// 1. Create Sample Customers (VIP and Regular)
List<Customer__c> sampleCustomers = new List<Customer__c>{
    new Customer__c(Name = 'Emily Watson', VIP_Customer__c = true),
    new Customer__c(Name = 'Marcus Vance', VIP_Customer__c = false),
    new Customer__c(Name = 'Sophia Martinez', VIP_Customer__c = true),
    new Customer__c(Name = 'Rahul Sharma', VIP_Customer__c = false)
};
insert sampleCustomers;

// 2. Create Restaurant Tables
List<Restaurant_Table__c> sampleTables = new List<Restaurant_Table__c>{
    new Restaurant_Table__c(Name = 'Table 1', Table_Number__c = 1, Capacity__c = 4, Status__c = 'Available'),
    new Restaurant_Table__c(Name = 'Table 2', Table_Number__c = 2, Capacity__c = 2, Status__c = 'Available'),
    new Restaurant_Table__c(Name = 'Table 3', Table_Number__c = 3, Capacity__c = 6, Status__c = 'Occupied'),
    new Restaurant_Table__c(Name = 'Table 4', Table_Number__c = 4, Capacity__c = 4, Status__c = 'Available'),
    new Restaurant_Table__c(Name = 'Table 5', Table_Number__c = 5, Capacity__c = 8, Status__c = 'Cleaning')
};
insert sampleTables;

// 3. Create Menu Items across categories with realistic Rupee (₹) pricing
List<Menu_Item__c> sampleMenuItems = new List<Menu_Item__c>{
    new Menu_Item__c(Name = 'Crispy Truffle Fries', Category__c = 'Starters', Price__c = 250.00, Description__c = 'Hand-cut potato fries tossed in truffle oil and parmesan cheese.', Vegetarian__c = true, Available__c = true, Preparation_Time__c = 10),
    new Menu_Item__c(Name = 'Buffalo Chicken Wings', Category__c = 'Starters', Price__c = 320.00, Description__c = 'Spicy glazed chicken wings served with celery and blue cheese sauce.', Vegetarian__c = false, Available__c = true, Preparation_Time__c = 15),
    new Menu_Item__c(Name = 'FoodHub Signature Burger', Category__c = 'Main Course', Price__c = 450.00, Description__c = 'Angus beef patty, smoked bacon, cheddar cheese & special sauce on brioche bun.', Vegetarian__c = false, Available__c = true, Preparation_Time__c = 20),
    new Menu_Item__c(Name = 'Wild Mushroom Risotto', Category__c = 'Main Course', Price__c = 520.00, Description__c = 'Creamy Arborio rice cooked with wild forest mushrooms, herbs & aged parmesan.', Vegetarian__c = true, Available__c = true, Preparation_Time__c = 25),
    new Menu_Item__c(Name = 'Molten Lava Cake', Category__c = 'Desserts', Price__c = 280.00, Description__c = 'Warm dark chocolate cake with a molten center, served with vanilla gelato.', Vegetarian__c = true, Available__c = true, Preparation_Time__c = 12),
    new Menu_Item__c(Name = 'Fresh Mango Smoothies', Category__c = 'Beverages', Price__c = 180.00, Description__c = 'Freshly blended Alphonso mangoes with crushed ice and mint.', Vegetarian__c = true, Available__c = true, Preparation_Time__c = 5)
};
insert sampleMenuItems;

System.debug('FoodHub Sample Data Successfully Inserted!');
