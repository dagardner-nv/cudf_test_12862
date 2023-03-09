#include "test_lib.hpp"

cudf::io::table_with_metadata load_table_from_csv(const std::string& filename)
{
    auto options = cudf::io::csv_reader_options::builder(cudf::io::source_info{filename});
    return cudf::io::read_csv(options.build());
}
