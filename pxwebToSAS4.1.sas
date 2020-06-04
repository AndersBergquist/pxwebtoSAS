/****************************************
Program: pxwebToSAS4
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 0.1

- output:
	1. S�tter makrot &update till 1 om uppdatering finns och 0 om det inte finns.
***********************************/


proc ds2;
	package work.pxWebToSAS4 / overwrite=yes;
		declare package work.pxweb_UppdateTableDate SCB_Date();
		declare package work.pxweb_makeJsonFraga SCB_GetJsonFraga();
		declare package work.pxweb_getData SCB_getData();
		declare package work.pxweb_gemensammametoder g();
		declare nvarchar(1000000) jsonFraga;
		declare integer defaultMaxCells;

		forward getDataStart;

		method pxwebtosas4();
			defaultMaxCells=50000;
		end;
******** getData varianter f�r att g�ra det s� flexibelt som m�jligt att h�mta data. start;
		method getData(varchar(500) inUrl);
			declare varchar(32) SASTabell tmpTable libname;
			declare integer maxCells;
			maxCells=defaultMaxCells;
			tmpTable=scan(inUrl, -1, '/') || strip(put(time(),8.));
			SASTabell=scan(inUrl, -1, '/');
			getDataStart(inUrl, 'work', SASTabell, maxCells, tmpTable);

		end;

		method getData(varchar(500) inUrl, varchar(8) SASLib);
			declare varchar(32) SASTabell tmpTable libname;
			declare integer maxCells;
			maxCells=defaultMaxCells;
			tmpTable=scan(inUrl, -1, '/') || strip(put(time(),8.));
			SASTabell=scan(inUrl, -1, '/');
			getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);

		end;

		method getData(varchar(500) inUrl, varchar(8) SASLib, varchar(32) SASTabell);
			declare integer maxCells;
			declare varchar(32) tmpTable;
			maxCells=defaultMaxCells;
			tmpTable=scan(inUrl, -1, '/') || strip(put(time(),8.));
			getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
		end;

		method getData(varchar(500) inUrl, integer maxCells, varchar(8) SASLib, varchar(32) SASTabell, varchar(32) tmpTable);
			getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
		end;
/*
		method getData(varchar(500) inUrl, varchar(32) tmpTable);
			declare varchar(32) SASTabell libname;
			declare integer maxCells;
			maxCells=defaultMaxCells;
			getDataStart(inUrl, 'work', SASTabell, maxCells, tmpTable);
		end;
*/
		method getData(varchar(500) inUrl, integer maxCells, varchar(32) tmpTable);
			declare varchar(32) SASTabell;
			getDataStart(inUrl, 'work', SASTabell, maxCells, tmpTable);
		end;

******** getData varianter f�r att g�ra det s� flexibelt som m�jligt att h�mta data. start;

		method getDataStart(varchar(500) iUrl, varchar(8) SASLib, varchar(32) SASTabell, integer maxCells, varchar(32) tmpTable);
			declare package hash h_jsonFragor();
			declare package hiter hi_jsonFragor(h_jsonFragor);
			declare package sqlstmt s();
			declare double tableUpdated dbUpdate;
			declare varchar(41) fullTabellNamn;
			declare varchar(250) fraga;
			declare integer ud rc i x ;
			declare integer starttid runTime loopStart;

			starttid=time();

			fullTabellNamn=SASLib || '.' || SASTabell;
			tableUpdated=SCB_Date.getSCBDate(iUrl);
			dbUpdate=SCB_Date.getDBDate(fullTabellNamn);
			if dbUpdate < tableUpdated then do;
				SCB_GetJsonFraga.skapaFraga(iUrl, maxCells, fullTabellNamn, tmpTable);
				fraga='{select jsonFraga from work.json_' || tmpTable || '}';
				h_jsonFragor.keys([jsonFraga]);
				h_jsonFragor.data([jsonFraga]);
				h_jsonFragor.dataset(fraga);
				h_jsonFragor.defineDone();
				rc=hi_jsonFragor.first([jsonFraga]);
				i=1;
				do until(hi_jsonFragor.next([jsonFraga]));
					loopStart=time();
					SCB_getData.hamtaData(iUrl, jsonFraga, tmpTable, fullTabellNamn);
					do while(time()-loopstart < 1);
					end;
				end;
				SCB_getData.closeTable();
				if g.finnsTabell(fullTabellNamn)^=0 then sqlexec('INSERT INTO ' || fullTabellNamn || ' SELECT * FROM work.' || tmpTable);
				else sqlexec('SELECT * INTO ' || fullTabellNamn || ' FROM work.' || tmpTable || '');
				sqlexec('DROP TABLE work.' || tmpTable);
				sqlexec('DROP TABLE work.meta_' || tmpTable || ';');
				sqlexec('DROP TABLE work.json_' || tmpTable || ';');
				ud=1;
*Uppdatera sas-tabellen.;
			end;
			else do;
				put 'pxWebToSAS.getDataStart: Det finns ingen uppdatering till' fullTabellNamn;
				ud=0;
			end;
			runtime=time()-starttid;
put 'H�mtningen tog' runTime 'sekunder';
		end;
	endpackage ;
run;quit;
