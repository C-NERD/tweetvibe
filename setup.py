## python script to setup project's dependencies
## for debian and arch linux only
## make sure to run with root permission
## has errors for now

from subprocess import run
from os import geteuid, putenv, environ
from pathlib import Path
import logging

SCRIPT_DIR = Path(__file__).parent
HOME_DIR = Path().home()

logging.basicConfig(level = logging.NOTSET, format = "%(levelname)s :: %(asctime)s -> %(message)s", force = True)
def check_if_root() -> bool :

    if geteuid() != 0:

        return False

    return True

def get_pkg_manager() -> str :
    ## for apt or pacman

    cmds = [
        ["apt", "-v"],
        ["pacman", "-v"]
    ]
    for cmd in cmds:

        try:

            output = run(cmd, text = True, capture_output = True)
            return cmd[0]
    
        except FileNotFoundError:

            continue

def get_manager_install_cmd(manager : str) -> str :

    if manager == "apt":

        return "install"

    elif manager == "pacman":

        return "-S"

if __name__ == "__main__":

    if not check_if_root():

        logging.info("run script as root user")
        quit(-1)

    pkg_manager = get_pkg_manager()
    install_cmd = get_manager_install_cmd(pkg_manager)
    if pkg_manager == None or install_cmd == None:

        logging.error("could not find apt or pacman")
        logging.info("quiting...")
        quit(-1)

    logging.info("updating to new version of python...")
    run(["sudo", pkg_manager, install_cmd, "python3"])
    
    logging.info("installing pip...")
    run(["sudo", pkg_manager, install_cmd, "pip"])

    logging.info("setting up nim...")
    run(["sudo", pkg_manager, install_cmd, "nim"])
    run(["nimble", "install", "choosenim"])
    
    logging.info("adding nimble bin dir to path")
    path = environ.get('PATH')
    environ["PATH"] = path + f":{HOME_DIR / '.nimble/bin'}"

    logging.info("install nim version 1.6.6")
    run(["choosenim", "update", "1.6.6"])

    logging.info("adding nim 1.6.6 to path")
    path = environ.get('PATH')
    environ["PATH"] = path + f":{HOME_DIR / '.choosenim/toolchains/nim-1.6.6/bin'}"

    logging.info("installing package dependencies...")
    ## install package dependencies
    run(["ls", "-a"])
    run(["pip", "install", "-r", "requirements.txt"])
    run(["nimble", "build"]) ## install dependencies and build frontend

    logging.info("creating .env file...")
    ## create .env file
    variables = [
        "SERVER_HOST=0.0.0.0",
        "SERVER_PORT=5000",
        "TWITTER_API_KEY=",
        "TWITTER_API_SECRET=",
        "TWITTER_BEARER_TOKEN=",
        "GOOGLE_API_KEY=",
        "SECRET_KEY=",
        "DATABASE_URI=mongodb://localhost:27017/"
    ]
    with open(".env", "w") as file:

        file.writelines(variables)
        file.close()
