******************************************************************************
* Author: 	Paul Madley-Dowd
* Date: 	17 May 2022
* Description:  Loads all required packages for use in PREPArE study data management. Add any required packages here in alphabetical order
******************************************************************************
* ssc install 
ssc install datacheck
ssc install distinct
ssc install sencode
ssc install unique 
ssc install psmatch2
ssc install stddiff, replace


* net install
net install grc1leg, from(http://www.stata.com/users/vwiggins/)