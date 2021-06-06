#include <string_view>

#include <restinio/all.hpp>

#include "../sgen/static.hpp"

using router_t = restinio::router::express_router_t<>;

int main() {
    auto router = std::make_unique<router_t>();

    router->http_get("/", [](auto req, [[maybe_unused]] auto params){
        req->create_response()
            .append_header(restinio::http_field::content_type, "text/html")
            .set_body(std::string_view(_binary_static_index_html_start, _binary_static_index_html_size))
            .done();
        return restinio::request_accepted();
    });

    using traits_t =
      restinio::traits_t<
         restinio::asio_timer_manager_t,
         restinio::single_threaded_ostream_logger_t,
         router_t >;
    std::cout << "Starting server." << std::endl;
    restinio::run(restinio::on_this_thread<traits_t>().port(8080).request_handler(std::move(router)));

    return 0;
}

