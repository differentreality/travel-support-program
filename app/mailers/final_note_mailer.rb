class FinalNoteMailer < ApplicationMailer

  def creation(to, final_note)
    @machine = final_note.machine
    @final_note = final_note
    mail(:to => to,  :subject => t(:mailer_subject_new_final_note, :type => @machine.class.model_name, :id => @machine.id))
  end
end
