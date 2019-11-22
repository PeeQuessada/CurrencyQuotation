public class requestCurrency {
    
    //Metodo retorna a cotação de uma moeda
    public static CurrencyQuotation__c requestAPI(CurrencyQuotation__c currencyQuote){      
        
        //Endpoint e requisição
        String endpoint = label.EndpointAPICurrency + currencyQuote.Name;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        //Atualiza os campos com o valor do retorno da API
        if(response.getStatusCode() == 200){
            requestCurrency.rateWrapper currencyWrapper = new rateWrapper().constructor(response.getBody());
            String currencyUpdate = label.currencyUpdate.replaceAll('\\s+', '');
            
            //Preenche cada campo com o novo valor, baseado na lista de campos disponivel (custom label)
            for(String currencyAux : currencyUpdate.split(';')){
                String fieldName  = currencyAux + '__c';                  
                Double fieldvalue = decimal.valueOf(currencyWrapper.rates.get(currencyAux));
                currencyQuote.put(fieldName, fieldvalue);
            }
            
        } else{
            currencyQuote.error__c = 'error in request API date: ' + datetime.now();
        }  
        
        return currencyQuote;
    }
    
    //Wrapper com construtor que transforma o JSON no formato da classe
    public class rateWrapper{
        public Map<String, String> rates {get;set;}
        public String base {get;set;}
        public Boolean error {get;set;}
        
        public rateWrapper constructor(String json){
            this.error = false;
            return (rateWrapper) System.JSON.deserialize(json, rateWrapper.class);
        }
    }
    
    //Metodo aura para busca de uma cotação
    @AuraEnabled
    public static CurrencyQuotation__c getCurrency(String baseCurrency){
        
        //Query para busca dos campos de uma moeda
        String query = 'SELECT Id, Error__c';
        for(String currencyAux : label.currencyUpdate.split(';')){
            query += ', ' + currencyAux + '__c';     
        }
        query += ' FROM CurrencyQuotation__c';
        List<CurrencyQuotation__c> listCurrencyQuote = database.query(query);
        
        //Verifica se existe um registro com o valor base igual ao solicitado
        for(CurrencyQuotation__c currencyAux : listCurrencyQuote){
            if(currencyAux.Name == baseCurrency)
                return currencyAux;
        }
        
        //Se nao for encontrado um registro com a moeda base requisitada ele faz uma nova requisição
        return requestCurrency.requestAPI(new CurrencyQuotation__c(Name = baseCurrency));
    }
    
}