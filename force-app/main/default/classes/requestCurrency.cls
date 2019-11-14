public class requestCurrency {

    public static CurrencyQuotation__c requestAPI(CurrencyQuotation__c currencyQuote, String baseCurrency){      
        
        if(currencyQuote == null)
            currencyQuote = new CurrencyQuotation__c();

        String base;
        if(baseCurrency != null && baseCurrency.trim() != '')
            base = baseCurrency;
        else 
            base = label.baseCurrency.replaceAll( '\\s+', '');
        
        String endpoint = label.EndpointAPICurrency + base;
        system.debug(endpoint);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        requestCurrency.rateWrapper getCurrencys;
        String error = '';
        
        if(response.getStatusCode() == 200){
            getCurrencys = new rateWrapper().parse(response.getBody());
            String currencyUpdate = label.currencyUpdate.replaceAll( '\\s+', '');
            
            for(String currencyAux : currencyUpdate.split(';')){
                String labelCurrency = currencyAux + '__c';  
                Double value = 0;
                
                try{
                    value = decimal.valueOf(getCurrencys.rates.get(currencyAux));
                } catch(Exception e){
                    error += 'error get field in API: ' + currencyAux + '; ';
                }
                
                try{
                	currencyQuote.put(labelCurrency, value);
                } catch(Exception e){
                    error += 'Error get field in Objct: ' + labelCurrency + 'in object; ';
                }
                
              }
        } else{
            error += 'error in request API date: ' + datetime.now();
        }
        	
        currencyQuote.error__c = error;
        currencyQuote.Name = base;      
        
		return currencyQuote;
    }
    
    public class rateWrapper{
        public Map<String, String> rates {get;set;}
        public String base {get;set;}
        public Boolean error {get;set;}
        
        public rateWrapper parse(String json){
            this.error = false;
            return (rateWrapper) System.JSON.deserialize(json, rateWrapper.class);
        }
    }
    
    public static CurrencyQuotation__c getCurrency(String baseCurrency){
        String defaultCurrency = label.baseCurrency.replaceAll( '\\s+', '');
        
        String query = 'SELECT Id, Error__c';
        for(String currencyAux : label.currencyUpdate.split(';')){
            query += ', ' + currencyAux + '__c';     
        }
        query += ' FROM CurrencyQuotation__c';
        
        List<CurrencyQuotation__c> listCurrencyQuote = database.query(query);
        
        for(CurrencyQuotation__c currencyAux : listCurrencyQuote){
            if(currencyAux.Name == baseCurrency)
                return currencyAux;
        }
        
        return requestCurrency.requestAPI(null, baseCurrency);
    }
    
}