public with sharing class TaxService {
  public class TaxResponse {
    public String country;
    public Decimal taxRate;
  }

  public static Decimal getTaxRate() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Tax_API_Credential/tax/rate');
    req.setMethod('GET');
    req.setHeader('Accept', 'application/json');
    req.setTimeout(10000);

    Http http = new Http();
    try {
      HttpResponse res = http.send(req);
      if (res.getStatusCode() == 200) {
        TaxResponse taxData = (TaxResponse) JSON.deserialize(
          res.getBody(),
          TaxResponse.class
        );
        if (taxData != null && taxData.taxRate != null) {
          return taxData.taxRate;
        }
      }
      return 10.0;
    } catch (Exception ex) {
      System.debug('Tax Service Callout Exception: ' + ex.getMessage());
      return 10.0;
    }
  }
}
