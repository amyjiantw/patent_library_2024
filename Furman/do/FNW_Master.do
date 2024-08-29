************************************************************************************************************************
* Master Do File
* Furman, Nagler, Watzinger: "Disclosure and Subsequent Innovation: Evidence from the Patent Depository Library Program"
* AEJ: Economic Policy
* December 2020
************************************************************************************************************************

************************************************************  Set Path
global dir "D:\Dropbox\02_Patent_Libraries\AEJ\Kit"
cd "$dir"
set more off, perm 

************************************************************ Necessary Programs

do "do/Setup.do"

************************************************************ Produce Data Sets

* This do file requires data sets that are not part of this replication kit but can be obtained easily. See ReadMe for more information. 

*do "0_data_preparation_AEJ_Kit.do"

************************************************************ Produce Tables

*** Main Text
do "do/Tab1.do"
do "do/Tab2.do"
do "do/Tab3.do"
do "do/Tab4.do"
do "do/Tab5.do"

*** Appendix
* Table A-1 not empirical
* Table A-2 not empirical
do "do/TabB1.do"
do "do/TabB3.do"
do "do/TabB4.do"
do "do/TabB5.do"

************************************************************ Produce Figures

*** Main Text
do "do/Fig1.do"
do "do/Fig2.do"
do "do/Fig3.do"
do "do/Fig4.do"
do "do/Fig5.do"
do "do/Fig6TabB2.do"
do "do/Fig7.do"
do "do/Fig8.do"

*** Appendix

do "do/FigB1.do"
do "do/FigB2.do"
do "do/FigB3.do"
do "do/FigB4.do"
do "do/FigB5.do"
do "do/FigB6.do"
* Figure C-1 not empirical
do "do/FigC2.do"
do "do/FigC3.do"
do "do/FigC4.do"
do "do/FigC5.do"