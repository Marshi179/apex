public with sharing class SharinPixImageSearchController { // to global if needed
    static Client clientInstance = new Client('sharinpix://34edb5d0-4dbf-47e5-a11d-9ddc34a285da:qpk0XHmupySkCsIfPXw1QXsSyNm8i7tu-baS7JzmZSdufQQ@azhar.ngrok.io/api/v1'); // Remove !

    @AuraEnabled
    public static Map<String, List<Report>> getReports() {
        List<Report> allReports = [SELECT Id, Name, FolderName FROM Report WHERE Format = 'Tabular' ORDER BY FolderName, Name];
        String currentFolderName = null, previousFolderName = null;
        Map<String, List<Report>> reportFolders = new Map<String, List<Report>>();
        for (Report rep : allReports) {
            currentFolderName = rep.FolderName;
            if (currentFolderName != previousFolderName) {
                reportFolders.put(currentFolderName, new List<Report> { rep });
            } else {
                reportFolders.get(currentFolderName).add(rep);
            }
            previousFolderName = currentFolderName;
        }
        return reportFolders;
    }

    @AuraEnabled
    public static List<String> getTagNames() {
        Map<String, Object> params = new Map<String, Object> { 'admin' => true };
        Integer page = 1;
        List<Object> tagsPage = new List<Object>();
        List<Object> allTags = new List<Object>();
        do {
            tagsPage = (List<Object>)clientInstance.get('/tags' + '?page=' + page++, params);
            allTags.addAll(tagsPage);
        } while (tagsPage.size() != 0);
        List<String> tagNames = new List<String>();
        for (Object o : allTags) {
            tagNames.add((String)((Map<String, Object>)o).get('name'));
        }
        return tagNames;
    }

    @AuraEnabled
    public static List<String> generateSearchUrls(Id reportId, List<Object> reportParameters, String tagOperator, List<String> selectedTags, Integer pageSize) {
        System.debug('reportId : ' + reportId);
        System.debug('reportParameters : ' + reportParameters);
        System.debug('tagOperator : ' + tagOperator);
        System.debug('selectedTags : ' + selectedTags);
        System.debug('pageSize : ' + pageSize);
        pageSize = Integer.valueOf(pageSize); // WTF ??

        List<String> urls = new List<String>();

        List<String> albumIds = getAlbumIdsFromReport(reportId, reportParameters);
        if (pageSize == 0) {
            pageSize = albumIds.size();
        }
        Map<String, String> query;
        String queryStr;
        for (Integer i = 0; i < i + pageSize && i < albumIds.size(); i += pageSize) {
            queryStr = generateQueryString(slice(albumIds, i, Math.min(i + pageSize, albumIds.size())), selectedTags, tagOperator);
            query = new Map<String, String> { 'q' => queryStr };
            urls.add('https://azhar.ngrok.io/search?search_bar=false&q=' + clientInstance.token(query));
            //urls.add('https://azhar.ngrok.io/search?search_bar=false&token=' + clientInstance.token(query));
            //urls.add('https://app.sharinpix.com/search?search_bar=false&q=' + clientInstance.token(query));
        }
        System.debug('urls: ' + JSON.serialize(urls));
        return urls;
    }

    private static List<String> getAlbumIdsFromReport(Id reportId, List<Object> reportParameters) {
        try {
            System.debug('reportParameters : ' + reportParameters);
            System.debug('reportParameters.size() : ' + reportParameters.size());
            Reports.ReportResults results;
            if (reportParameters != null && reportParameters.size() != 0) {
                Reports.ReportDescribeResult reportDescribe = Reports.ReportManager.describeReport(reportId);
                Reports.ReportMetadata reportMetadata = reportDescribe.getReportMetadata();
                Reports.ReportFilter filter;
                String reportParameter;
                for (Integer i = 0; i < reportParameters.size(); i++) {
                    filter = reportMetadata.getReportFilters()[i];
                    reportParameter = String.valueOf(reportParameters[i]);
                    if (reportParameter.trim() InstanceOf Id) {
                        reportParameter = (Id)reportParameter.trim();
                    }
                    filter.setValue(reportParameter);
                }
                results = Reports.ReportManager.runReport(reportId, reportMetadata, true);
            } else {
                results = Reports.ReportManager.runReport(reportId, true);
            }
            Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get('T!T');

            List<String> albumIds = new List<String>();
            Integer columnIndex = 0;
            List<Reports.ReportDataCell> dataCells;

            for (Reports.ReportDetailRow detailRow : factDetails.getRows()) {
                dataCells = detailRow.getDataCells();
                albumIds.add((String)dataCells[columnIndex].getValue());
            }
            return albumIds;
        } catch (Exception e) {
            throw new SharinPixException('Error in generating report - ' + e.getCause() + '[' + e.getLineNumber() + ']: ' + e.getMessage());
        }
    }

    private static String generateQueryString(List<String> albumIds, List<String> selectedTags, String tagOperator) {
        if (albumIds == null) albumIds = new List<String>();
        if (selectedTags == null) selectedTags = new List<String>();
        if (albumIds.size() == 0) return '';
        if (tagOperator == null || tagOperator == '') tagOperator = 'OR';
        if (tagOperator != 'AND' && tagOperator != 'OR') throw new SharinPixException('Invalid parameters.');

        String albumIdsString = '';
        albumIdsString = '"' + String.join(albumIds, '" "') + '"';
        if (selectedTags.size() == 0) return albumIdsString;

        String selectedTagsString = '"' + String.join(selectedTags, '" ' + tagOperator + ' "') + '"';
        return 'tags:(+(' + albumIdsString + ') +(' + selectedTagsString + '))';
    }

    private static List<String> slice(List<String> original, Integer startIndex, Integer endIndex) {
        if (startIndex == 0 && endIndex == original.size()) {
            return original;
        }
        List<String> sliced = new List<String>();
        for (Integer i = startIndex; i < endIndex && i < original.size(); i++) {
            sliced.add(original[i]);
        }
        return sliced;
    }
}