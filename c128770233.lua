--스파클 아르카디아 싱크로
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsType,TYPE_TUNER),1,1,aux.FilterBoolFunctionEx(Card.IsSetCard,0x760),1,99)
	c:EnableReviveLimit()

	--① 토큰 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.tkcon)
	e1:SetTarget(s.tktg)
	e1:SetOperation(s.tkop)
	c:RegisterEffect(e1)

	--② 자신 필드 몬스터 대상 불가
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	--③ 묘지 몬스터 복사
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.copycost)
	e3:SetOperation(s.copyop)
	c:RegisterEffect(e3)
end

--① 조건
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
--① 토큰 생성 타깃
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,128770234,0x760,TYPES_TOKEN,0,0,4,RACE_WARRIOR,ATTRIBUTE_DARK) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end
--① 토큰 특수 소환
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,128770234,0x760,TYPES_TOKEN,0,0,4,RACE_WARRIOR,ATTRIBUTE_DARK) then return end
	local token=Duel.CreateToken(tp,128770234)
	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
end

--③ 복사 효과 코스트: 묘지에서 스파클 아르카디아 제외
function s.copyfilter(c)
	return c:IsSetCard(0x760) and c:IsMonster() and c:IsAbleToRemoveAsCost()
end
function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.copyfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.copyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	e:SetLabel(g:GetFirst():GetCode())
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
--③ 효과 복사 및 공격/수비 변경
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local code=e:GetLabel()
	local g=Duel.GetMatchingGroup(function(tc) return tc:IsCode(code) end,tp,LOCATION_REMOVED,0,nil)
	local tc=g:GetFirst()
	if not tc or not c:IsRelateToEffect(e) then return end
	local atk=tc:GetBaseAttack()
	local def=tc:GetBaseDefense()
	c:SetBaseAttack(atk)
	c:SetBaseDefense(def)
	c:CopyEffect(code,RESET_EVENT+RESETS_STANDARD,1)
end
