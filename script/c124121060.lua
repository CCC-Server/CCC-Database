--섀터드 섀도우 스테라
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Link.AddProcedure(c,nil,2,2,s.pfun1)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.con1)
	e1:SetCost(s.cost1)
	e1:SetTarget(s.tar1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_LEAVE_FIELD)
	-- 변경점 C 반영: 필드를 삭제하고 오직 묘지(LOCATION_GRAVE)에서만 발동하도록 변경
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.con2)
	e2:SetCost(s.cost2)
	e2:SetTarget(s.tar2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
end
function s.pfil1(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_DARK,lc,sumtype,tp) and c:IsRace(RACE_WINGEDBEAST,lc,sumtype,tp)
end
function s.pfun1(g,lc,sumtype,tp)
	return g:IsExists(s.pfil1,1,nil,lc,sumtype,tp)
end
function s.con1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_LINK)
end
-- 변경점 A 반영: 레벨 4 제약(c:IsLevel(4)) 삭제
function s.cfil1(c)
	return c:IsAbleToGraveAsCost() and c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_WINGEDBEAST)
end
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.cfil1,tp,LOCATION_DECK,0,nil)
	if chk==0 then
		return #g>0
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sg=g:Select(tp,1,1,nil)
	Duel.SendtoGrave(sg,REASON_COST)
end
function s.tfil1(c)
	return c:IsAbleToHand() and c:IsCode(24094653)
end
function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tfil1,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.tfil1,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
-- 변경점 B 반영: 상대 효과 파괴(REASON_EFFECT) 조건 삭제 및 상대(rp==1-tp)에 의한 유발 필터링
function s.nfil2(c,tp,rp)
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousControler(tp) and
		c:GetPreviousTypeOnField()&TYPE_FUSION~=0 and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsPreviousSetCard(0xfa2) and rp==1-tp
end
function s.con2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 안전 연산을 위해 데미지 스텝 제외 검증식 결합
	return not eg:IsContains(c) and eg:IsExists(s.nfil2,1,nil,tp,rp) and Duel.GetCurrentPhase()~=PHASE_DAMAGE
end
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(1)
	return true
end
-- 변경점 B 텍스트 반영: 덱에서 "초융합(48130397)" 1장만을 골라 묘지로 보내도록 조건 압축
function s.tfil2(c)
	return c:IsCode(48130397) and c:CheckActivateEffect(true,true,false)~=nil and c:IsAbleToGraveAsCost()
end
function s.tar2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		if e:GetLabel()==0 then return false end
		e:SetLabel(0)
		return c:IsAbleToExtraAsCost()
			and Duel.IsExistingMatchingCard(s.tfil2,tp,LOCATION_DECK,0,1,nil)
	end
	e:SetLabel(0)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tfil2,tp,LOCATION_DECK,0,1,1,nil)
	local te,ceg,cep,cev,cre,cr,crp=g:GetFirst():CheckActivateEffect(false,true,true)
	Duel.SendtoDeck(c,nil,2,REASON_COST)
	Duel.SendtoGrave(g,REASON_COST)
	e:SetProperty(te:GetProperty())
	local tg=te:GetTarget()
	if tg then
		tg(e,tp,ceg,cep,cev,cre,cr,crp,1)
	end
	te:SetLabelObject(e:GetLabelObject())
	e:SetLabelObject(te)
	Duel.ClearOperationInfo(0)
end
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if not te then
		return
	end
	e:SetLabelObject(te:GetLabelObject())
	local op=te:GetOperation()
	if op then
		op(e,tp,eg,ep,ev,re,r,rp)
	end
end