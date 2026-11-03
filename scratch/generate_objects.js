const fs = require("fs");
const path = require("path");

const basePath = path.join(
  __dirname,
  "..",
  "force-app",
  "main",
  "default",
  "objects"
);

const objects = [
  {
    name: "Customer__c",
    label: "Customer",
    pluralLabel: "Customers",
    nameField: { name: "Name", label: "Customer Name", type: "Text" },
    fields: [
      { api: "Phone__c", label: "Phone", type: "Phone" },
      { api: "Email__c", label: "Email", type: "Email" },
      {
        api: "VIP_Customer__c",
        label: "VIP Customer",
        type: "Checkbox",
        defaultValue: "false"
      },
      {
        api: "Total_Orders__c",
        label: "Total Orders",
        type: "Number",
        precision: 18,
        scale: 0,
        defaultValue: "0"
      },
      {
        api: "Total_Amount_Spent__c",
        label: "Total Amount Spent",
        type: "Currency",
        precision: 18,
        scale: 2,
        defaultValue: "0"
      }
    ]
  },
  {
    name: "Restaurant_Table__c",
    label: "Restaurant Table",
    pluralLabel: "Restaurant Tables",
    nameField: { name: "Name", label: "Table Name/Number", type: "Text" },
    fields: [
      {
        api: "Table_Number__c",
        label: "Table Number",
        type: "Text",
        length: 50
      },
      {
        api: "Capacity__c",
        label: "Capacity",
        type: "Number",
        precision: 4,
        scale: 0,
        defaultValue: "2"
      },
      {
        api: "Status__c",
        label: "Status",
        type: "Picklist",
        values: ["Available", "Occupied", "Reserved", "Cleaning"],
        defaultValue: "Available"
      }
    ]
  },
  {
    name: "Menu_Item__c",
    label: "Menu Item",
    pluralLabel: "Menu Items",
    nameField: { name: "Name", label: "Item Name", type: "Text" },
    fields: [
      {
        api: "Category__c",
        label: "Category",
        type: "Picklist",
        values: ["Starters", "Main Course", "Desserts", "Beverages"],
        defaultValue: "Main Course"
      },
      {
        api: "Price__c",
        label: "Price",
        type: "Currency",
        precision: 18,
        scale: 2,
        defaultValue: "0"
      },
      {
        api: "Description__c",
        label: "Description",
        type: "LongTextArea",
        length: 1000,
        visibleLines: 3
      },
      {
        api: "Vegetarian__c",
        label: "Vegetarian",
        type: "Checkbox",
        defaultValue: "false"
      },
      {
        api: "Available__c",
        label: "Available",
        type: "Checkbox",
        defaultValue: "true"
      },
      {
        api: "Preparation_Time__c",
        label: "Preparation Time (mins)",
        type: "Number",
        precision: 4,
        scale: 0,
        defaultValue: "15"
      }
    ]
  },
  {
    name: "Order__c",
    label: "Order",
    pluralLabel: "Orders",
    nameField: {
      name: "Name",
      label: "Order Number",
      type: "AutoNumber",
      displayFormat: "ORD-{00000}"
    },
    fields: [
      {
        api: "Customer__c",
        label: "Customer",
        type: "Lookup",
        referenceTo: "Customer__c"
      },
      {
        api: "Table__c",
        label: "Table",
        type: "Lookup",
        referenceTo: "Restaurant_Table__c"
      },
      { api: "Order_Date__c", label: "Order Date", type: "DateTime" },
      {
        api: "Status__c",
        label: "Status",
        type: "Picklist",
        values: [
          "Draft",
          "Confirmed",
          "Preparing",
          "Ready",
          "Served",
          "Cancelled"
        ],
        defaultValue: "Draft"
      },
      {
        api: "Subtotal__c",
        label: "Subtotal",
        type: "Currency",
        precision: 18,
        scale: 2,
        defaultValue: "0"
      },
      {
        api: "Discount_Percent__c",
        label: "Discount %",
        type: "Percent",
        precision: 5,
        scale: 2,
        defaultValue: "0"
      },
      {
        api: "Discount_Amount__c",
        label: "Discount Amount",
        type: "Currency",
        precision: 18,
        scale: 2,
        defaultValue: "0"
      },
      {
        api: "Tax_Rate__c",
        label: "Tax Rate %",
        type: "Percent",
        precision: 5,
        scale: 2,
        defaultValue: "0"
      },
      {
        api: "Tax__c",
        label: "Tax Amount",
        type: "Currency",
        precision: 18,
        scale: 2,
        defaultValue: "0"
      },
      {
        api: "Grand_Total__c",
        label: "Grand Total",
        type: "Currency",
        precision: 18,
        scale: 2,
        defaultValue: "0"
      },
      {
        api: "Discount_Status__c",
        label: "Discount Status",
        type: "Picklist",
        values: ["None", "Pending Approval", "Approved", "Rejected"],
        defaultValue: "None"
      },
      {
        api: "Cancellation_Reason__c",
        label: "Cancellation Reason",
        type: "LongTextArea",
        length: 1000,
        visibleLines: 3
      }
    ]
  },
  {
    name: "Order_Item__c",
    label: "Order Item",
    pluralLabel: "Order Items",
    nameField: {
      name: "Name",
      label: "Order Item ID",
      type: "AutoNumber",
      displayFormat: "OI-{00000}"
    },
    fields: [
      {
        api: "Order__c",
        label: "Order",
        type: "MasterDetail",
        referenceTo: "Order__c",
        relationshipName: "Order_Items"
      },
      {
        api: "Menu_Item__c",
        label: "Menu Item",
        type: "Lookup",
        referenceTo: "Menu_Item__c"
      },
      {
        api: "Quantity__c",
        label: "Quantity",
        type: "Number",
        precision: 5,
        scale: 0,
        defaultValue: "1"
      },
      {
        api: "Unit_Price__c",
        label: "Unit Price",
        type: "Currency",
        precision: 18,
        scale: 2,
        defaultValue: "0"
      },
      {
        api: "Total_Price__c",
        label: "Total Price",
        type: "Formula",
        formula: "Quantity__c * Unit_Price__c",
        formulaTreatNullNumberAs: "BlankAsZero"
      }
    ]
  }
];

function getObjectMetaXML(obj) {
  const nameFieldXML =
    obj.nameField.type === "AutoNumber"
      ? `
    <nameField>
        <displayFormat>${obj.nameField.displayFormat}</displayFormat>
        <label>${obj.nameField.label}</label>
        <type>AutoNumber</type>
    </nameField>`
      : `
    <nameField>
        <label>${obj.nameField.label}</label>
        <type>Text</type>
    </nameField>`;

  return `<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>${obj.label}</label>
    <pluralLabel>${obj.pluralLabel}</pluralLabel>
    <sharingModel>${obj.fields.some((f) => f.type === "MasterDetail") ? "ControlledByParent" : "ReadWrite"}</sharingModel>
    <deploymentStatus>Deployed</deploymentStatus>
    ${nameFieldXML}
</CustomObject>
`;
}

function getFieldMetaXML(field) {
  let typeXML = `<type>${field.type}</type>`;
  if (field.type === "Phone") {
    typeXML += `\n    <required>false</required>`;
  } else if (field.type === "Email") {
    typeXML += `\n    <required>false</required>`;
  } else if (field.type === "Checkbox") {
    typeXML += `\n    <defaultValue>${field.defaultValue}</defaultValue>`;
  } else if (
    field.type === "Number" ||
    field.type === "Currency" ||
    field.type === "Percent"
  ) {
    typeXML += `\n    <precision>${field.precision}</precision>\n    <scale>${field.scale}</scale>`;
    if (field.defaultValue !== undefined) {
      typeXML += `\n    <defaultValue>${field.defaultValue}</defaultValue>`;
    }
  } else if (field.type === "Text") {
    typeXML += `\n    <length>${field.length || 255}</length>`;
  } else if (field.type === "LongTextArea") {
    typeXML += `\n    <length>${field.length || 32768}</length>\n    <visibleLines>${field.visibleLines || 3}</visibleLines>`;
  } else if (field.type === "Picklist") {
    const valueSets = field.values
      .map(
        (v) => `
            <value>
                <fullName>${v}</fullName>
                <default>${v === field.defaultValue}</default>
                <label>${v}</label>
            </value>`
      )
      .join("");
    typeXML += `
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            ${valueSets}
        </valueSetDefinition>
    </valueSet>`;
  } else if (field.type === "Lookup") {
    typeXML += `\n    <referenceTo>${field.referenceTo}</referenceTo>\n    <relationshipName>${field.api.replace("__c", "s")}</relationshipName>\n    <deleteConstraint>SetNull</deleteConstraint>`;
  } else if (field.type === "MasterDetail") {
    typeXML += `\n    <referenceTo>${field.referenceTo}</referenceTo>\n    <relationshipName>${field.relationshipName}</relationshipName>\n    <writeRequiresMasterRead>false</writeRequiresMasterRead>\n    <reparentableMasterDetail>false</reparentableMasterDetail>`;
  } else if (field.type === "Formula") {
    typeXML = `<type>Currency</type>
    <formula>${field.formula}</formula>
    <formulaTreatBlanksAs>${field.formulaTreatNullNumberAs}</formulaTreatBlanksAs>
    <precision>18</precision>
    <scale>2</scale>`;
  }

  return `<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>${field.api}</fullName>
    <label>${field.label}</label>
    ${typeXML}
</CustomField>
`;
}

objects.forEach((obj) => {
  const objDir = path.join(basePath, obj.name);
  const fieldsDir = path.join(objDir, "fields");
  fs.mkdirSync(fieldsDir, { recursive: true });

  fs.writeFileSync(
    path.join(objDir, `${obj.name}.object-meta.xml`),
    getObjectMetaXML(obj)
  );

  obj.fields.forEach((f) => {
    fs.writeFileSync(
      path.join(fieldsDir, `${f.api}.field-meta.xml`),
      getFieldMetaXML(f)
    );
  });
});

console.log(
  "Successfully generated metadata for all custom objects and fields!"
);
