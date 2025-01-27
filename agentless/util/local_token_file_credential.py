from datetime import datetime
import os
import time
import json
import jwt
from azure.core.credentials import AccessToken, TokenCredential
import pytz
from loguru import logger


class LocalTokenFileCredential(TokenCredential):
    def __init__(self):
        self.cached_token = None

    def decode_jwt(self, token):
        try:
            decoded_token = jwt.decode(token, options={"verify_signature": False})
            return decoded_token
        except jwt.DecodeError as ex:
            logger.error(f"Failed to decode JWT token: {str(ex)}")
            return None

    def get_token(self, *scopes, **kwargs):
        if 'AUTODEV_DIR' not in os.environ:
            raise Exception("Environment variable 'AUTODEV_DIR' is not defined, it must be set to the repository root directory.")

        file_name = f"{os.environ['AUTODEV_DIR']}/tokenfile.json"

        while True:
            try:
                # Check if the cached token is still valid
                if self.cached_token and self.cached_token.expires_on > int(time.time()):
                    return self.cached_token

                logger.info(f'Reading authentication token from {file_name}')
                with open(file_name, 'r', encoding="utf-8") as f:
                    data = json.load(f)
                    if len(data) > 0:
                        accessToken = data["accessToken"]
                        if len(accessToken) > 0:
                            decoded_token = self.decode_jwt(accessToken)
                            self.cached_token = AccessToken(accessToken, decoded_token["exp"])

                            local_tz = pytz.timezone(time.tzname[0])
                            expires_on_timestamp = datetime.fromtimestamp(self.cached_token.expires_on, local_tz)
                            if self.cached_token.expires_on < int(time.time()):
                                raise ValueError("Token expired at {expires_on_timestamp} ({local_tz})")
                            minutes_until_expiration = (self.cached_token.expires_on - int(time.time())) // 60
                            logger.info(f"Token successfully loaded, expiring at {expires_on_timestamp} ({local_tz}) in {minutes_until_expiration} mins")
                            return self.cached_token
                    logger.error("Token file was empty")
            except IOError as ex:
                logger.error(f"IOError while reading token file: {str(ex)}.")
            except json.JSONDecodeError as ex:
                logger.error(f"JSONDecodeError while reading token file: {str(ex)}.")
            except ValueError as ex:
                logger.error(f"Invalid token value: {str(ex)}.")

            logger.warning("Check if you have authenticated using `az login --use-device-code`. Retrying in 10 seconds...")
            time.sleep(10)
