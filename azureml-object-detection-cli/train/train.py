import argparse
import os
import mlflow
from ultralytics import YOLO


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--data", required=True)
    parser.add_argument("--epochs", type=int, default=3)
    parser.add_argument("--project", required=True)
    parser.add_argument("--name", default="experiment")
    return parser.parse_args()


def main():
    args = parse_args()

    tracking_uri = os.environ.get("MLFLOW_TRACKING_URI")
    experiment_name = os.environ.get("MLFLOW_EXPERIMENT_NAME", "yolov8-experiment")

    if tracking_uri:
        mlflow.set_tracking_uri(tracking_uri)

    mlflow.set_experiment(experiment_name)

    with mlflow.start_run():
        model = YOLO(args.model)
        model.train(
            data=args.data,
            epochs=args.epochs,
            project=args.project,
            name=args.name,
        )


if __name__ == "__main__":
    main()
