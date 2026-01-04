--명왕의 옥좌 - 심연의 알현실
local s,id=GetID()
function s.initial_effect(c)
	--기재된 카드명: 명왕룡 반달기온
	s.listed_names={24857466}

	--①: 서치 및 추가 회수 (발동)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	--[수정됨] CATEGORY_GRAVE_ACTION 삭제 (이전 오류 수정 반영)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--②: 파괴/제외 시 데미지 0 (묘지 발동)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.damcon_gy)
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_REMOVE)
	e3:SetCondition(s.damcon_rm)
	c:RegisterEffect(e3)

	--카운터 함정 발동 체크를 위한 글로벌 효과
	if not s.global_check_det then
		s.global_check_det=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
end

--글로벌 체크: 카운터 함정이 발동되었는지 기록
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsActiveType(TYPE_COUNTER) then
		Duel.RegisterFlagEffect(rp,id,RESET_PHASE+PHASE_END,0,1)
	end
end

--[추가됨] 안전한 카드명 기재 확인 함수 (aux.IsCodeListed 대체)
function s.safe_check_listed(c, target_code)
	local codes = c.listed_names
	if not codes then return false end
	for _,code in ipairs(codes) do
		if code==target_code then return true end
	end
	return false
end

--① 효과 필터: 반달기온 관련 몬스터 서치
function s.thfilter(c)
	--aux.IsCodeListed 대신 s.safe_check_listed 사용
	return (c:IsCode(24857466) or s.safe_check_listed(c, 24857466)) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

--① 효과 필터: 카운터 함정 회수
function s.recfilter(c)
	return c:IsType(TYPE_COUNTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	--추가 효과 가능성은 Info에 포함만 시킴 (확정 아님)
	if Duel.GetFlagEffect(tp,id)>0 then
		Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
	end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		
		--추가 효과: 카운터 함정 발동 기록이 있고, 대상이 있으면 처리
		local g2=Duel.GetMatchingGroup(s.recfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		if Duel.GetFlagEffect(tp,id)>0 and #g2>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=g2:Select(tp,1,1,nil)
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end

--② 효과 조건: 묘지로 보내졌을 경우 (파괴)
function s.cfilter_gy(c,tp)
	return c:IsReason(REASON_DESTROY) and c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.damcon_gy(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter_gy,1,nil,tp)
end

--② 효과 조건: 제외되었을 경우 (앞면)
function s.cfilter_rm(c,tp)
	return c:IsFaceup() and c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.damcon_rm(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter_rm,1,nil,tp)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--이 턴, 상대 효과 데미지 0
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetValue(s.damval)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	--효과 데미지 무효 (보조)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

function s.damval(e,re,val,r,rp,rc)
	if bit.band(r,REASON_EFFECT)~=0 and rp~=e:GetHandlerPlayer() then return 0 end
	return val
end