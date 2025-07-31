#!/usr/bin/env python3

import apt
import subprocess
import sys
from python_on_whales import docker

def update_system():
    print("Checking for package updates using python-apt...")
    cache = apt.Cache()
    cache.update()
    cache.open(None)

    upgrades = [pkg for pkg in cache if pkg.is_upgradable]
    if not upgrades:
        print("No packages to upgrade.")
    else:
        print(f"Found {len(upgrades)} packages to upgrade:")
        for pkg in upgrades:
            print(f" - {pkg.name} {pkg.installed.version} -> {pkg.candidate.version}")
            pkg.mark_upgrade()

        print("Applying upgrades...")
        try:
            cache.commit()
            print("Upgrades applied successfully.")
        except Exception as e:
            print(f"Error applying upgrades: {e}")
            sys.exit(1)

    print("Cleaning up unused packages and cache via apt-get commands...")
    subprocess.run("sudo apt autoremove -y", shell=True, check=True)
    subprocess.run("sudo apt clean", shell=True, check=True)
    print("System update complete.\n")

def check_ufw():
    print("Checking UFW firewall status...")
    result = subprocess.run("sudo ufw status verbose", shell=True, text=True, capture_output=True)
    print(result.stdout.strip())
    if "Status: active" in result.stdout:
        print("UFW is active and running.\n")
    else:
        print("Warning: UFW is not active. Consider enabling the firewall.\n")

def check_docker():
    print("Checking Docker service status using python-on-whales...")
    try:
        # docker.ps() throws if Docker daemon is not running or no permission
        containers = docker.ps()
        print(f"Docker is running. {len(containers)} container(s) currently active.\n")
    except Exception as e:
        print(f"Warning: Docker service may not be running or accessible. Exception:\n{e}")
        print("Trying to start Docker service...")
        subprocess.run("sudo systemctl start docker", shell=True, check=True)
        print("Docker started.\n")

def check_python_version():
    print("Checking installed Python version...")
    result = subprocess.run("python3 --version", shell=True, text=True, capture_output=True)
    print(f"Python version: {result.stdout.strip()}\n")

def main():
    update_system()
    check_ufw()
    check_docker()
    check_python_version()
    print("All checks completed.")

if __name__ == "__main__":
    main()
