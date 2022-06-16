//
//  CountryCodeMapper.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 16/06/2022.
//

import Foundation

let countryCodeMapping: Dictionary<String, String> = [
    "0004": "Afghanistan",
    "0248": "Åland Islands",
    "0008": "Albania",
    "0012": "Algeria",
    "0016": "American Samoa",
    "0020": "Andorra",
    "0024": "Angola",
    "0660": "Anguilla",
    "0010": "Antarctica",
    "0028": "Antigua and Barbuda",
    "0032": "Argentina",
    "0051": "Armenia",
    "0533": "Aruba",
    "0036": "Australia",
    "0040": "Austria",
    "0031": "Azerbaijan",
    "0044": "Bahamas",
    "0048": "Bahrain",
    "0050": "Bangladesh",
    "0052": "Barbados",
    "0112": "Belarus",
    "0056": "Belgium",
    "0084": "Belize",
    "0204": "Benin",
    "0060": "Bermuda",
    "0064": "Bhutan",
    "0068": "Bolivia (Plurinational State of)",
    "0535": "Bonaire, Sint Eustatius and Saba",
    "0070": "Bosnia and Herzegovina",
    "0072": "Botswana",
    "0074": "Bouvet Island",
    "0076": "Brazil",
    "0086": "British Indian Ocean Territory",
    "0096": "Brunei Darussalam",
    "0100": "Bulgaria",
    "0854": "Burkina Faso",
    "0108": "Burundi",
    "0132": "Cabo Verde",
    "0116": "Cambodia",
    "0120": "Cameroon",
    "0124": "Canada",
    "0136": "Cayman Islands",
    "0140": "Central African Republic",
    "0148": "Chad",
    "0152": "Chile",
    "0156": "China",
    "0162": "Christmas Island",
    "0166": "Cocos (Keeling) Islands",
    "0170": "Colombia",
    "0174": "Comoros",
    "0178": "Congo",
    "0180": "Congo, Democratic Republic of the",
    "0184": "Cook Islands",
    "0188": "Costa Rica",
    "0384": "Côte d'Ivoire",
    "0191": "Croatia",
    "0192": "Cuba",
    "0531": "Curaçao",
    "0196": "Cyprus",
    "0203": "Czechia",
    "0208": "Denmark",
    "0262": "Djibouti",
    "0212": "Dominica",
    "0214": "Dominican Republic",
    "0218": "Ecuador",
    "0818": "Egypt",
    "0222": "El Salvador",
    "0226": "Equatorial Guinea",
    "0232": "Eritrea",
    "0233": "Estonia",
    "0748": "Eswatini",
    "0231": "Ethiopia",
    "0238": "Falkland Islands (Malvinas)",
    "0234": "Faroe Islands",
    "0242": "Fiji",
    "0246": "Finland",
    "0250": "France",
    "0254": "French Guiana",
    "0258": "French Polynesia",
    "0260": "French Southern Territories",
    "0266": "Gabon",
    "0270": "Gambia",
    "0268": "Georgia",
    "0276": "Germany",
    "0288": "Ghana",
    "0292": "Gibraltar",
    "0300": "Greece",
    "0304": "Greenland",
    "0308": "Grenada",
    "0312": "Guadeloupe",
    "0316": "Guam",
    "0320": "Guatemala",
    "0831": "Guernsey",
    "0324": "Guinea",
    "0624": "Guinea-Bissau",
    "0328": "Guyana",
    "0332": "Haiti",
    "0334": "Heard Island and McDonald Islands",
    "0336": "Holy See",
    "0340": "Honduras",
    "0344": "Hong Kong",
    "0348": "Hungary",
    "0352": "Iceland",
    "0356": "India",
    "0360": "Indonesia",
    "0364": "Iran (Islamic Republic of)",
    "0368": "Iraq",
    "0372": "Ireland",
    "0833": "Isle of Man",
    "0376": "Israel",
    "0380": "Italy",
    "0388": "Jamaica",
    "0392": "Japan",
    "0832": "Jersey",
    "0400": "Jordan",
    "0398": "Kazakhstan",
    "0404": "Kenya",
    "0296": "Kiribati",
    "0408": "Korea (Democratic People's Republic of)",
    "0410": "Korea, Republic of",
    "0414": "Kuwait",
    "0417": "Kyrgyzstan",
    "0418": "Lao People's Democratic Republic",
    "0428": "Latvia",
    "0422": "Lebanon",
    "0426": "Lesotho",
    "0430": "Liberia",
    "0434": "Libya",
    "0438": "Liechtenstein",
    "0440": "Lithuania",
    "0442": "Luxembourg",
    "0446": "Macao",
    "0450": "Madagascar",
    "0454": "Malawi",
    "0458": "Malaysia",
    "0462": "Maldives",
    "0466": "Mali",
    "0470": "Malta",
    "0584": "Marshall Islands",
    "0474": "Martinique",
    "0478": "Mauritania",
    "0480": "Mauritius",
    "0175": "Mayotte",
    "0484": "Mexico",
    "0583": "Micronesia (Federated States of)",
    "0498": "Moldova, Republic of",
    "0492": "Monaco",
    "0496": "Mongolia",
    "0499": "Montenegro",
    "0500": "Montserrat",
    "0504": "Morocco",
    "0508": "Mozambique",
    "0104": "Myanmar",
    "0516": "Namibia",
    "0520": "Nauru",
    "0524": "Nepal",
    "0528": "Netherlands",
    "0540": "New Caledonia",
    "0554": "New Zealand",
    "0558": "Nicaragua",
    "0562": "Niger",
    "0566": "Nigeria",
    "0570": "Niue",
    "0574": "Norfolk Island",
    "0807": "North Macedonia",
    "0580": "Northern Mariana Islands",
    "0578": "Norway",
    "0512": "Oman",
    "0586": "Pakistan",
    "0585": "Palau",
    "0275": "Palestine, State of",
    "0591": "Panama",
    "0598": "Papua New Guinea",
    "0600": "Paraguay",
    "0604": "Peru",
    "0608": "Philippines",
    "0612": "Pitcairn",
    "0616": "Poland",
    "0620": "Portugal",
    "0630": "Puerto Rico",
    "0634": "Qatar",
    "0638": "Réunion",
    "0642": "Romania",
    "0643": "Russian Federation",
    "0646": "Rwanda",
    "0652": "Saint Barthélemy",
    "0654": "Saint Helena, Ascension and Tristan da Cunha",
    "0659": "Saint Kitts and Nevis",
    "0662": "Saint Lucia",
    "0663": "Saint Martin (French part)",
    "0666": "Saint Pierre and Miquelon",
    "0670": "Saint Vincent and the Grenadines",
    "0882": "Samoa",
    "0674": "San Marino",
    "0678": "Sao Tome and Principe",
    "0682": "Saudi Arabia",
    "0686": "Senegal",
    "0688": "Serbia",
    "0690": "Seychelles",
    "0694": "Sierra Leone",
    "0702": "Singapore",
    "0534": "Sint Maarten (Dutch part)",
    "0703": "Slovakia",
    "0705": "Slovenia",
    "0090": "Solomon Islands",
    "0706": "Somalia",
    "0710": "South Africa",
    "0239": "South Georgia and the South Sandwich Islands",
    "0728": "South Sudan",
    "0724": "Spain",
    "0144": "Sri Lanka",
    "0729": "Sudan",
    "0740": "Suriname",
    "0744": "Svalbard and Jan Mayen",
    "0752": "Sweden",
    "0756": "Switzerland",
    "0760": "Syrian Arab Republic",
    "0158": "Taiwan, Province of China",
    "0762": "Tajikistan",
    "0834": "Tanzania, United Republic of",
    "0764": "Thailand",
    "0626": "Timor-Leste",
    "0768": "Togo",
    "0772": "Tokelau",
    "0776": "Tonga",
    "0780": "Trinidad and Tobago",
    "0788": "Tunisia",
    "0792": "Turkey",
    "0795": "Turkmenistan",
    "0796": "Turks and Caicos Islands",
    "0798": "Tuvalu",
    "0800": "Uganda",
    "0804": "Ukraine",
    "0784": "United Arab Emirates",
    "0826": "United Kingdom of Great Britain and Northern Ireland",
    "0840": "United States of America",
    "0581": "United States Minor Outlying Islands",
    "0858": "Uruguay",
    "0860": "Uzbekistan",
    "0548": "Vanuatu",
    "0862": "Venezuela (Bolivarian Republic of)",
    "0704": "Viet Nam",
    "0092": "Virgin Islands (British)",
    "0850": "Virgin Islands (U.S.)",
    "0876": "Wallis and Futuna",
    "0732": "Western Sahara",
    "0887": "Yemen",
    "0894": "Zambia",
    "0716": "Zimbabwe"
]
