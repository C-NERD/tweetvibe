## python script to setup project's dependencies
## for debian and arch linux only
## make sure to run with root permission

from platform import python_version_tuple, system
from subprocess import run
from re import search
from os import geteuid
import logging

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

    logging.info("checking python version...")
    ## check if python version is less than 3.7, if so update python
    py_ver = python_version_tuple()
    update_py = False
    if int(py_ver[0]) < 3:

        update_py = True
    
    elif int(py_ver[1]) < 7:

        update_py = True

    if update_py:

        logging.info("updating to new version of python...")
        run(["sudo", pkg_manager, install_cmd, "python3"])
    
    logging.info("installing pip...")
    run(["sudo", pkg_manager, install_cmd, "pip"])

    logging.info("checking nim version...")
    ## check if nim version is less than 1.4.0 if so update nim
    update_nim = False
    try:

        nim_ver_info = run(["nim", "-v"], text = True, capture_output = True)
        if nim_ver_info == None:

            update_nim = True
        
        else:

            nim_ver = search(r"[0-9].[0-9].[0-9]", nim_ver_info.stdout)
            nim_ver_splited = nim_ver[0].split(".")

            if int(nim_ver_splited[0]) < 1:

                update_nim = True
        
            elif int(nim_ver_splited[1]) < 4:

                update_nim = True

    except FileNotFoundError:

        update_nim = True

    if update_nim:

        logging.info("updating to new version of nim...")
        run(["sudo", pkg_manager, install_cmd, "nim"])
        run(["nimble", "install", "choosenim"])
        run(["choosenim", "update", "1.6.6"])

    logging.info("installing package dependencies...")
    ## install package dependencies
    run(["pip", "install", "-r requirements.txt"])
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
