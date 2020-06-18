﻿/****************************************
Program: pxweb_makeJsonFraga.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.4
Uppgift:
- Skapar json-fråga till datahämtning och lagrar frågorna i filen work.json_tmpTabell;
***********************************/
proc ds2;
	package &prgLib..pxweb_makeJsonFraga / overwrite=yes;
		declare package &prgLib..pxweb_GemensammaMetoder g();
		declare package &prgLib..pxweb_getMetaData getMetaData();
		declare package hash h_subFragor();
		declare package hash h_jsonFragor();
		declare package hiter hi_jsonFragor(h_jsonFragor);
		declare package sqlstmt s_jsonFragor;
		declare package sqlstmt s_countJsonFragor;
		declare varchar(250) subCode;
		declare varchar(25000) subFraga;
		declare varchar(10000) jsonFraga;
		declare integer numJsonFragor;
		forward skapaSubFraga skapaFragehash skapaFrageHashHelper skapaFrageHashHelper2 countRows;

		method pxweb_makeJsonFraga();
		end;

		method skapaFraga(varchar(500) iUrl, integer maxCells, varchar(41) fullTabellNamn, varchar(32) tmpTable);
			declare integer antalCodes;
			getMetaData.getData(iURL, maxCells, fullTabellNamn, tmpTable);
			skapaSubFraga();
			skapaFragehash(tmpTable);
			countRows(tmpTable);
*			h_jsonFragor.output('work.json_' || tmpTable);
		end;

		method skapaFragehash(varchar(32) tmpTable);
			declare integer maxDeep;
			declare varchar(1000) sql_skapajsontabell;
			sqlexec('create table work.json_' || tmpTable || ' (jsonFraga varchar(1000000))');
			s_jsonFragor = _new_ sqlstmt('insert into work.json_' || tmpTable || '(jsonFraga) values(?)',[jsonFraga]);
			
			maxDeep=getMetaData.getAntalCodes();
			skapaFrageHashHelper(1,maxDeep,'');
			s_jsonFragor.delete();
		end;

		method skapaFrageHashHelper(int deep, int maxDeep, varchar(100000) qstring);
			declare varchar(100000) v_qstring[800];
			declare varchar(100000) local_qstring;
			declare integer AntalFragor rc i k;
			subCode=getMetaData.getLevelCode(deep);
        ** Läser in frågorna till vektor. Start **;
			antalFragor=0;
*h_subFragor.output('work.subfragor');
			rc=h_subFragor.find([subCode],[subCode, subFraga]);
			do while(rc=0);
				antalFragor=antalFragor+1;
				v_qstring[antalFragor]=subFraga;
				rc=h_subFragor.find_next([subCode, subFraga]);
			end;
        ** Läser in frågorna till vektor. Slut **;
			do k=1 to antalFragor;
				if deep=1 then do;
					local_qstring=v_qstring[k];
				end;
				else do;
					local_qstring=qstring || ',' || v_qstring[k];
				end;
				if deep = maxDeep then do;
					jsonFraga='{"query": [' || local_qstring || ',  {"code":"ContentsCode", "selection":{"filter":"all", "values":["*"]}} ], "response": {"format": "json"}}';
*					h_jsonFragor.add([jsonFraga],[jsonFraga]);
					s_jsonFragor.execute();
				end;
				else do;
					skapaFrageHashhelper(deep+1, maxDeep, local_qstring);
				end;
			end;
		end;

		method skapaSubFraga();
			declare varchar(25000) stubFraga;
			declare varchar(250) title code text values valueTexts elimination "time";
			declare integer rundaNr iDataStorlek sizeDataStorlek iMetaData sizeMetaData antal cellerPerValue x;

			h_subFragor.multidata('MULTIDATA');
 			h_subFragor.keys([subCode]);
			h_subFragor.data([subCode, subFraga]);
			h_subFragor.ordered('A');
			h_subFragor.defineDone();

			iDataStorlek=1;
			sizeDataStorlek=getMetaData.dataStorlekNumItem();
			getMetaData.dataStorlekFirst(subCode,antal,cellerPerValue);
			do until(iDataStorlek>sizeDataStorlek);
				iMetaData=1;
				* Alla variabler väljs;
/*				if antal=cellerPerValue then do;
					subFraga='{"code":"' || subCode || '", "selection":{"filter":"all", "values":["*"]}}';
					h_subFragor.ref([subCode],[subCode, subFraga]);
				end;
				* En variabel i taget väljs;
				else*/ 
				if cellerPerValue=1 then do;
					sizeMetaData=getMetaData.metaDataNumItem();
					getMetaData.metaDataFirst(title, code, text, values, valueTexts, elimination, "time");
					do until(iMetaData>sizeMetaData);
					getMetaData.metaDataNext(title, code, text, values, valueTexts, elimination, "time");
						if subCode=code then do;
							stubFraga='{"code":"' || subCode || '", "selection":{"filter":"item", "values":["';
							subFraga=stubFraga || values || '"';
							subFraga=subFraga || ']}}';
							h_subFragor.add([subCode],[subCode, subFraga]);
						end;
					iMetaData=iMetaData+1;
					end;
				end;
				* Delmängd av variabler väljs;
				else do;
					rundaNr=0;
					stubFraga='{"code":"' || subCode || '", "selection":{"filter":"item", "values":[';
					iMetaData=1;
					sizeMetaData=getMetaData.metaDataNumItem();
					getMetaData.metaDataFirst(title, code, text, values, valueTexts, elimination, "time");
					do until(iMetaData>sizeMetaData);
						if subCode=code then do; *and values ^= '' ??;
							rundaNr=rundaNr+1;
							if rundaNr=cellerPerValue then do;
								stubFraga=stubFraga || ', "' || values || '"]}}';
								subFraga=stubFraga;
								h_subFragor.add([subCode],[subCode, subFraga]);
								rundaNr=0;
								stubFraga='{"code":"' || subCode || '", "selection":{"filter":"item", "values":[';
							end;
							else if rundaNr=1 then do;
								stubFraga=stubFraga || '"' || values || '"';
							end;
							else do;
								stubFraga=stubFraga || ', "' || values || '"';
							end;
						end;
					getMetaData.metaDataNext(title, code, text, values, valueTexts, elimination, "time");
					iMetaData=iMetaData+1;
					end;
					if (rundaNr^=cellerPerValue and rundaNr^=0) then do;
put stubFraga= rundaNr= cellerPerValue= iMetaData= sizeMetaData=;
						stubFraga=stubFraga || ']}}';
						subFraga=stubFraga;
						h_subFragor.add([subCode],[subCode, subFraga]);
						rundaNr=0;
						stubFraga='{"code":"' || subCode || '", "selection":{"filter":"item", "values":"';
					end;
				end;
				getMetaData.dataStorlekNext(subCode,antal,cellerPerValue);
			iDataStorlek=iDataStorlek+1;
			end;
*h_subFragor.output('work.subfraga');
		end;*skapaSubFraga;
* Ett antal metoder för att kunna hämta jsonfrågor från packetet;
*** Hämtar första fråga;
		method countRows(varchar(32) tmpTable);
		declare integer x;
			s_countJsonFragor = _new_ sqlstmt('select count(*) as numJsonFragor from work.json_' || tmpTable);
			s_countJsonFragor.execute();
			s_countJsonFragor.fetch([numJsonFragor]);
			s_countJsonFragor.delete();
		end;
		method getNumItems()returns integer ;

			return numJsonFragor;
		end;

	endpackage;
run;quit;