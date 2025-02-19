from vllm.utils import FlexibleArgumentParser
from vllm.engine.arg_utils import nullable_str

def add_arg_parser(parser: FlexibleArgumentParser) -> FlexibleArgumentParser:
    parser.add_argument("--mp-host",
                        type=nullable_str,
                        default=None,
                        help="host name")
    parser.add_argument("--mp-port", type=int, default=9999, help="port number")
    parser.add_argument(
        "--root-path",
        type=nullable_str,
        default=None,
        help="FastAPI root_path when app is behind a path based routing proxy")

    return parser