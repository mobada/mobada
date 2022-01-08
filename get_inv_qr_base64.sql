create or replace function get_inv_qr_base64(p_tag1 varchar2,p_tag2 varchar2,p_tag3 varchar2,p_tag4 varchar2,p_tag5 varchar2) return varchar2
/*Function to return  base64 to be used in qr code for electronic invoice as Zatca.gov.sa phase 1
Mobada 05-12-2021
tag1 : Seller name, it could be in english or arabic, so I user lengthb to count its length by bytes because arabic charaters strored in 2 bytes not one as english
tag2 : Tax registeration number
tag3 : Invoice date & time stamp, Should be YYYY-MM-DD HH:MI:SS ends with Z
tag4 : Total invoice amount including VAT, preferred to be 2 decimal digits as they do in thier example, Should be not formated it cause an error in ZAKAT Qr scanner
tag5 : Tax amount, preferred to be 2 decimal digits as they do in thier example, Should be not formated it cause an error in ZAKAT Qr scanner

tips:
1. Use lengthb for arabic cahcartes.
2. Use to_char(number,'0x') to convert numbers of tag and tage vaule length also into hex before convert all text to base64, if you use normal conversion it will be another number it will deal
with 1 number as example as a character not 1 as a number it will be 31 not 01
3. We should convert all values to hex before concatenated them then convert the all text to base64
4. Then we should extract base64 as varchar2 to be in the right frmat wanted by Zatca.gov.sa
5. You should replace chr(10) and chr(13) from bas64 before return because utl_raw.cast_to_varchar2 coverts it into lines each 64 character
*/
is
l_tag1 varchar2(4000) :=p_tag1;
l_tag1_len number;

l_tag2 varchar2(4000) :=p_tag2;
l_tag2_len number;

l_tag3 varchar2(4000) :=p_tag3;
l_tag3_len number;

l_tag4 varchar2(4000) :=p_tag4;
l_tag4_len number;

l_tag5 varchar2(4000) :=p_tag5;
l_tag5_len number;

l_qr_hex varchar2(32000);
l_qr_hex_raw  raw(500);
l_qr_base64 varchar2(500);

l_nls varchar2(100);
--Check character set
cursor nls
is
select
value from v$nls_parameters
WHERE parameter IN ( 'NLS_CHARACTERSET');
begin
open nls;
fetch nls into l_nls;
close nls;

--Check if characterset is not UTF8 then convert it to UTF8 because of arabic so you can but any tag will hold arbic her
if l_nls != 'AL32UTF8' then
l_tag1 := CONVERT(l_tag1 , 'AL32UTF8',l_nls) ;
l_tag3 := CONVERT(l_tag3, 'AL32UTF8',l_nls) ;
end if;
--Get tags length bu using lengthb because of arabic characters is stored in two bytes not one as english characters
l_tag1_len := lengthb(l_tag1);
l_tag2_len := lengthb(l_tag2);
l_tag3_len := lengthb(l_tag3);
l_tag4_len := lengthb(l_tag4);
l_tag5_len := lengthb(l_tag5);

--Convert tags to hex before concatenate
l_tag1 := rawtohex(utl_raw.cast_to_raw(l_tag1));
l_tag2 := rawtohex(utl_raw.cast_to_raw(l_tag2));
l_tag3 := rawtohex(utl_raw.cast_to_raw(l_tag3));
l_tag4 := rawtohex(utl_raw.cast_to_raw(l_tag4));
l_tag5 := rawtohex(utl_raw.cast_to_raw(l_tag5));

--Concatenate the the hex string, I will usre to_char to convert number of tag and its length to hex
l_qr_hex := to_char(1,'0x')||to_char(l_tag1_len,'0x')||l_tag1||to_char(2,'0x')||to_char(l_tag2_len,'0x')||l_tag2||to_char(3,'0x')||to_char(l_tag3_len,'0x')||l_tag3||to_char(4,'0x')||to_char(l_tag4_len,'0x')||l_tag4||to_char(5,'0x')||to_char(l_tag5_len,'0x')||l_tag5;
l_qr_hex := replace(l_qr_hex,' ',''); 
l_qr_hex_raw := l_qr_hex;
l_qr_base64 := utl_raw.cast_to_varchar2(utl_encode.base64_encode(l_qr_hex_raw));

return REPLACE(replace(l_qr_base64,chr(10)),chr(13));
end get_inv_qr_base64;
