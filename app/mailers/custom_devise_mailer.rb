# frozen_string_literal: true

class CustomDeviseMailer < ApplicationMailer
  FRONTEND_URL = ENV.fetch("FRONTEND_URL", "http://localhost:4000")

  def reset_password_instructions(record, token, opts = {})
    opts[:subject] = "Password Reset Instructions"
    @reset_url = "#{FRONTEND_URL}/reset-password?token=#{token}"

    mail(to: record.email, subject: opts[:subject]) do |format|
      format.text { render plain: "Use this link to reset your password: #{@reset_url}" }
      format.html do
        render html: "<p>Use this link to reset your password:</p><a href='#{@reset_url}'>Reset Password</a>".html_safe
      end
    end
  end
end
