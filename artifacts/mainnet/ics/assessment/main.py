import sys

# Import the scoring functions from the engagement and experience modules
from engagement.main import main as engagement_main
from experience.main import main as experience_main

def main():
    if len(sys.argv) < 2:
        print("Usage: python main.py <address1> [<address2> ...]")
        return

    print("==== Proof of Engagement ====")
    engagement_main()
    print("\n==== Proof of Experience ====")
    experience_main()

if __name__ == "__main__":
    main()