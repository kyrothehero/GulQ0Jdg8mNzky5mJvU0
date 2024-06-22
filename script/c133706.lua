--T-0 Mauler
local T0_SETNAME = 0x69ac
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon procedure
    c:EnableReviveLimit()
	Link.AddProcedure(c,nil,2,2,s.link_check)

	--When this card is Special Summoned: You can add 1 "T-0" monster from your Deck or GY to your hand.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	--e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.add_target)
	e1:SetOperation(s.add_operation)
	c:RegisterEffect(e1)

    --You can target 1 face-up monster you control; 
    --This turn, that monster can attack twice each Battle Phase, also it inflicts piercing battle damage.
	local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.maul_condition)
	e2:SetTarget(s.maul_target)
	e2:SetOperation(s.maul_operation)
	c:RegisterEffect(e2)
end

function s.link_check(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,T0_SETNAME,lc,sumtype,tp)
end

function s.add_filter(c)
	return c:IsMonster() and c:IsSetCard(T0_SETNAME) and c:IsAbleToHand()
end
function s.add_target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.add_filter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
end
function s.add_operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.add_filter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

function s.maul_condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsAbleToEnterBP()
end
function s.maul_filter(c)
	return c:IsFaceup() and not c:IsHasEffect(EFFECT_EXTRA_ATTACK)
end
function s.maul_target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.maul_filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.maul_filter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.maul_filter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.maul_operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
        --Target card can attack twice
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EXTRA_ATTACK)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)

        --Target card inflicts piercing
        local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetDescription(3208)
		e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_PIERCE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	end
end
