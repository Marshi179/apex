public class SObjectWrapper {
	public sObject sobj;
	public Schema.SObjectType sobjectType; 
	public TagImage tagImg;
	
	public SObjectWrapper(Id recordId, string jsonfile) {
		sobjectType = recordId.getSObjectType();
		sobj = sobjectType.newSObject(recordId);

		tagImg = (TagImage) JSON.deserialize(jsonfile, TagImage.class);
		tagImg.image.populate();
	}

	public map<string, Schema.SObjectField> fieldMap(){
		return sobjecttype.getDescribe().fields.getMap();
	}

	public Database.SaveResult executeAction(){
		for(Action action: tagImg.tag.action.actions){
			if (fieldMap().containsKey(action.field_name)){
				Schema.SobjectField field = fieldMap().get(action.field_name);
				if (action.value == 'custom'){
					if (verifyPermission(new list<Schema.SobjectField>{ field })){
						assignValue(action.field_name, action.custom_value);
					}
				}
				else if (action.value == 'gps'){
					boolean isStandardField = action.field_name.contains('__c') ? false : true;
					string latitudeFieldName = action.field_name.contains('__c') ? action.field_name.split('__c')[0]+'__latitude__s' : action.field_name.split('Address')[0]+'latitude';
					string longitudeFieldName = action.field_name.contains('__c') ? action.field_name.split('__c')[0]+'__longitude__s' : action.field_name.split('Address')[0]+'longitude';
						
					if (fieldType(field) == Schema.DisplayType.Location || isStandardField){
						if (verifyPermission(new list<Schema.SobjectField>{ fieldMap().get(latitudeFieldName), fieldMap().get(longitudeFieldName)})){
							assignValue(latitudeFieldName, tagImg.image.getX('latitude'));
							assignValue(longitudeFieldName, tagImg.image.getX('longitude'));
						}
					}
				}
				else {
					if (verifyPermission(new list<Schema.SobjectField>{ field })){
						assignValue(action.field_name, tagImg.image.getX(action.value));
					}
				}
			}
		}//end for
		Database.SaveResult result = Database.update(sobj, true);

		return result;
	}

	public void assignValue(string fieldname, object value){
		if(string.isblank(fieldname)){ return; }
		Schema.DescribeFieldResult fieldResult = fieldmap().get(fieldname).getDescribe();
		Schema.DisplayType fieldType = fieldResult.getType();
		Object fieldValue = null;
		boolean validated = false;

		try {
			if( fieldType == Schema.DisplayType.Boolean ){
				if (value == 'true' || value == 'false'){
					fieldValue = Boolean.valueOf(value);
					validated = true;
				}
			} else if( fieldType == Schema.DisplayType.Currency ){
				fieldValue = Decimal.valueOf(double.valueof(value));
				validated = true;
			} else if( fieldType == Schema.DisplayType.Integer ){
				fieldValue = Integer.valueOf(value);
				validated = true;
			} else if( fieldType == Schema.DisplayType.Percent || fieldType == Schema.DisplayType.Double ){
				fieldValue = Double.valueOf(value);
				validated = true;
			} else if( fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.TextArea ){
				fieldValue = string.valueof(value);
				validated = true;
			} else if( fieldType == Schema.DisplayType.URL ){
				new Url(string.valueof(value));
				fieldValue = string.valueof(value);
				validated = true;
			}
		}
		catch(Exception e){

		}

		if (validated){
			sobj.put(fieldname, fieldValue);	
		}
	}

	public boolean verifyPermission(list<Schema.SObjectField> lstfield){
		return Crud.ISUPDATEABLE(sobjecttype, lstfield);
	}

	public Schema.DisplayType fieldType(Schema.SObjectField field){
		return field.getDescribe().getType();
	}
}