%let prgLib=work;
%macro setInstLib;
	%global instLib;
    %if %symexist(_clientapp) %then %do;
        %if &_clientapp = 'SAS Studio' %then %do;
            %let instLib=%sysfunc(tranwrd(%sysfunc(dequote(&_sasprogramfile)), %scan(%unquote(&_sasprogramfile),-1,/), ));	    
	%end;
	%else %if &_clientapp = 'SAS Enterprise Guide' %then %do;
	    %let instLib=%sysfunc(tranwrd(%sysfunc(dequote(&_CLIENTPROJECTPATH)), %sysfunc(dequote(&_CLIENTPROJECTname)), ));
	%end;
    %end;
    %else %do;
        %let instLib=%sysfunc(tranwrd(%sysfunc(dequote(%sysget(SAS_EXECFILEPATH))), %scan(%unquote(%sysget(SAS_EXECFILEPATH)),-1,\), ));
    %end;
%mend setInstLib;
%setInstLib;
run;
filename instMap "&instLib";
%include instMap('pxweb_Gemensamma_Metoder.sas');
%include instMap('pxweb_table_update_date.sas');
%include instMap('pxweb_getMetaData.sas');
%include instMap('pxweb_makeJsonFraga.sas');
%include instMap('pxweb_Skapa_Output_Tabell.sas');
%include instMap('pxweb_skapaStmtFraga.sas');
%include instMap('pxweb_getData.sas');
%include instMap('pxwebToSAS4.sas');

run;
