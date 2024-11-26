class Validators::PasswordMaxLength < ActiveModel::Validator
  def validate(record)
    any_field_too_long = options[:fields].any? do |field|
      field_value = record.send(field)
      field_value && field_value.bytesize > ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED
    end
    record.errors.add(:password, :password_too_long) if any_field_too_long
  end
end
