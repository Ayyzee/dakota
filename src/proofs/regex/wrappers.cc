// http://www.cplusplus.com/reference/regex/regex_search

template <class charT, class Alloc, class traits>
bool regex_search (const charT* s,
                   match_results<const charT*, Alloc>& m,
                   const basic_regex<charT,traits>& rgx,
                   regex_constants::match_flag_type flags = regex_constants::match_default);

template <class ST, class SA, class Alloc, class charT, class traits>
bool regex_search (const basic_string<charT,ST,SA>& s,
                   match_results<typename basic_string<charT,ST,SA>::const_iterator,Alloc>& m,
                   const basic_regex<charT,traits>& rgx,
                   regex_constants::match_flag_type flags = regex_constants::match_default);

//bool std::regex_search(char const*, std::cmatch&, std::regex&, regex_constants::match_flag_type) // 1=c_str,  2=c_str  match
//bool std::regex_search(std::string, std::match&,  std::regex&, regex_constants::match_flag_type) // 1=string, 2=string match

//==

// std::string std::regex_replace(char const*, std::regex&, char const*  fmt, regex_constants::match_flag_type) // 1=c_str,  3=c_str
// std::string std::regex_replace(char const*, std::regex&, std::string& fmt, regex_constants::match_flag_type) // 1=c_str,  3=string
// std::string std::regex_replace(std::string, std::regex&, char const*  fmt, regex_constants::match_flag_type) // 1=string, 3=c_str
// std::string std::regex_replace(std::string, std::regex&, std::string& fmt, regex_constants::match_flag_type) // 1=string, 3=string
