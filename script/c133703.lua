--T-0 Kamikaze
local T0_SETNAME = 0x69ac
local s,id=GetID()
function s.initial_effect(c)
    --If your opponent Normal or Special Summons a monster(s): 
    --You can discard this card; Special Summon this card from the GY, then destroy this card on the field,
    --then Special Summon 1 "T-0" monster from your hand or Deck, except "T-0 Kamikaze".
    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.ss_condition)
	e1:SetCost(s.ss_cost)
	e1:SetTarget(s.ss_target)
	e1:SetOperation(s.ss_operation)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(s.ns_condition)
	c:RegisterEffect(e2)

    --If this card on the field is destroyed by card effect, except "T-0 Kamikaze", or by battle:
    --You can add 1 "T-0" Spell/Trap from your Deck to your hand.
    local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.add_condition)
	e3:SetTarget(s.add_target)
	e3:SetOperation(s.add_operation)
	c:RegisterEffect(e3)
end

function s.ss_condition(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end
function s.ns_condition(e,tp,eg,ep,ev,re,r,rp)
    return ep~=tp
end
function s.ss_cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDiscardable() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function s.ss_target(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk == 0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,c,1,0,0)
end
function s.ss_filter(c,e,tp)
	return c:IsSetCard(T0_SETNAME) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP) and not c:IsCode(id)
end
function s.ss_operation(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    --if not c:IsRelateToEffect(e) then return end
    if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)<=0 then return end
    Duel.BreakEffect()
	if Duel.Destroy(c,REASON_EFFECT)<=0 then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.ss_filter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

function s.add_condition(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_EFFECT+REASON_BATTLE)~=0 and e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD) 
		and not (re and re:GetHandler():IsCode(id))
end
function s.add_filter(c,e,tp)
	return c:IsSetCard(T0_SETNAME) and c:IsSpellTrap()
end
function s.add_target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.add_filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.add_operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.add_filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
