import sys

# Import the scoring functions from the engagement and experience modules
from engagement.main import main as engagement_main
from experience.main import main as experience_main
from humanity.main import main as humanity_main

def main():
    if len(sys.argv) < 2:
        print("Usage: python main.py <address1> [<address2> ...]")
        return

    print("\n==== Proof of Experience ====")
    experience_score = experience_main()
    print("\n==== Proof of Humanity ====")
    humanity_score = humanity_main()
    print("==== Proof of Engagement ====")
    engagement_score = engagement_main()
    print("\n==== Assessment Completed ====")
    print(f"Total Experience Score: {experience_score} " + ("✅" if experience_score else "❌"))
    print(f"Total Humanity Score: {humanity_score} " + ("✅" if humanity_score else "❌"))
    print(f"Total Engagement Score: {engagement_score} " + ("✅" if engagement_score else "❌"))
    print("Sum of all scores: ", experience_score + humanity_score + engagement_score)

if __name__ == "__main__":
    main()
