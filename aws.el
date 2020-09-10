;;; aws.el --- Utility functions for working with AWS -*- lexical-binding: t -*-

;; Copyright (c) 2020 Daniel Kraus <daniel@kraus.my>

;; Author: Daniel Kraus <daniel@kraus.my>
;; URL: https://github.com/dakra/aws.el
;; Keywords: amazon, aws, convenience, tools
;; Version: 0.1
;; Package-Requires: ((emacs "25.2"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; `aws.el' provides functions for the aws cli
;; The command line tool `aws' must be present.
;;
;; FIXME: This is currently only for personal use and the only thing
;; that's working is seeting your AWS environment variables while reading
;; the 2-factor-auth code.


;;; Code:
(require 'async)
(require 'auth-source)


;;; Customization

(defgroup aws nil
  "AWS CLI Interface"
  :prefix "aws-"
  :group 'tools
  :link '(url-link "https://github.com/dakra/aws.el"))

(defcustom aws-exec "aws"
  "Name of the aws executable."
  :type 'string)

(defcustom aws-duration 129600
  "How long the token is valid."
  :type 'integer)

(defcustom aws-serial-number ""
  "AWS serial-number.
Something like arn:aws:iam::0123456:mfa/your.user"
  :type 'string)



;;; Interactive commands

(defun aws-finish-func (proc)
  "Set AWS access environment variables.
JSON is read from PROC output."
  (with-current-buffer (process-buffer proc)
    (goto-char (point-min))
    (let* ((credentials       (assoc-default 'Credentials     (json-read)))
           (access-key-id     (assoc-default 'AccessKeyId     credentials))
           (secret-access-key (assoc-default 'SecretAccessKey credentials))
           (session-token     (assoc-default 'SessionToken    credentials)))
      (setenv "AWS_ACCESS_KEY_ID" access-key-id)
      (setenv "AWS_SECRET_ACCESS_KEY" secret-access-key)
      (setenv "AWS_SESSION_TOKEN" session-token)))
  (message "AWS auth environment variables set."))

;;;###autoload
(defun aws-set-session-token (token-code)
  "Set AWS credentials reading TOKEN-CODE."
  (interactive (list (read-passwd "Token Code: ")))
  (async-start-process "aws sts get-session-token" aws-exec #'aws-finish-func
                       "sts" "get-session-token"
                       "--duration-seconds" (format "%s" aws-duration)
                       "--serial-number" aws-serial-number
                       "--token-code" token-code))

(provide 'aws)
;;; aws.el ends here
