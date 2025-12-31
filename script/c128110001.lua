--유네티스 시그나투스
local s,id=GetID()
function s.initial_effect(c)
	--[스피릿 & 펜듈럼 공통 설정]
	Pendulum.AddProcedure(c)
	
	--[펜듈럼 효과 ①]: 패로 되돌리고 스피릿 일반 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetRange(LOCATION_PZONE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	--[펜듈럼 효과 ②]: 메인 페이즈 기동 - 명칭 제약 적용
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.pstg)
	e2:SetOperation(s.psop)
	c:RegisterEffect(e2)
	
	--[몬스터 효과 ①]: 펜듈럼 소환 실행
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.pentg)
	e3:SetOperation(s.penop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
	
	--[몬스터 효과 ②]: 바운스 감지 -> P세팅+서치+일소
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_TO_HAND)
	e5:SetRange(LOCATION_MZONE)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCountLimit(1,{id,3})
	e5:SetCondition(s.rtcon)
	e5:SetTarget(s.rttg)
	e5:SetOperation(s.rtop)
	c:RegisterEffect(e5)
	
	--[몬스터 효과 ③]: 엔드 페이즈 바운스 (강제)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,4))
	e6:SetCategory(CATEGORY_TOHAND)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e6:SetCode(EVENT_PHASE+PHASE_END)
	e6:SetRange(LOCATION_MZONE+LOCATION_EXTRA)
	e6:SetCountLimit(1)
	e6:SetCondition(s.retcon)
	e6:SetTarget(s.rettg)
	e6:SetOperation(s.retop)
	c:RegisterEffect(e6)
end
s.listed_series={0xc80} 
function s.cfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsSetCard(0xc80) and c:IsSummonType(SUMMON_TYPE_NORMAL)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.nsfilter(c)
	return c:IsType(TYPE_SPIRIT) and c:IsSummonable(true,nil)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand()
		and Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoHand(c,nil,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local g=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
		if #g>0 then
			Duel.Summon(tp,g:GetFirst(),true,nil)
		end
	end
end

function s.psfilter(c,e,tp,lscale,rscale)
	return c:IsSetCard(0xc80) and c:IsType(TYPE_PENDULUM)
		and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_GRAVE))
		and c:GetLevel()>lscale and c:GetLevel()<rscale
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.pstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local c=e:GetHandler()
		local pc=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
		if pc==c then pc=Duel.GetFieldCard(tp,LOCATION_PZONE,1) end
		if not pc then return false end
		
		local lscale=c:GetScale()
		local rscale=pc:GetScale()
		if lscale>rscale then lscale,rscale=rscale,lscale end
		
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.psfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp,lscale,rscale)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.psop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c,sump,sumtype,sumpos,targetp,se) 
		return (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM 
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	local pc=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
	if pc==c then pc=Duel.GetFieldCard(tp,LOCATION_PZONE,1) end
	if not pc then return end
	
	local lscale=c:GetScale()
	local rscale=pc:GetScale()
	if lscale>rscale then lscale,rscale=rscale,lscale end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.psfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp,lscale,rscale)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanPendulumSummon(tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_EXTRA)
end
function s.penop(e,tp,eg,ep,ev,re,r,rp)
	Duel.PendulumSummon(tp)
end

function s.rtfilter(c,tp)
	return c:IsSetCard(0xc80) and c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.rtcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.rtfilter,1,nil,tp)
end
function s.thfilter(c)
	return c:IsSetCard(0xc80) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.nsfilter2(c)
	return c:IsSetCard(0xc80) and c:IsSummonable(true,nil)
end
function s.rttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp) 
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end
function s.rtop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not Duel.CheckPendulumZones(tp) then return end
	if Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g)
			Duel.ShuffleHand(tp)
			if Duel.IsExistingMatchingCard(s.nsfilter2,tp,LOCATION_HAND,0,1,nil) 
				and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
				local sg=Duel.SelectMatchingCard(tp,s.nsfilter2,tp,LOCATION_HAND,0,1,1,nil)
				if #sg>0 then
					local tc=sg:GetFirst()
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_SUMMON_PROC)
					e1:SetCondition(s.ntcon)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					tc:RegisterEffect(e1)
					Duel.Summon(tp,tc,true,nil)
				end
			end
		end
	end
	
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetDescription(aux.Stringid(id,5))
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.splimit)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end
function s.ntcon(e,c,minc)
	if c==nil then return true end
	return minc==0 and c:GetLevel()>4 and Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsSetCard(0xc80)
end

function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return (c:IsSummonType(SUMMON_TYPE_NORMAL) or c:IsSummonType(SUMMON_TYPE_PENDULUM))
		and c:IsFaceup() and c:GetTurnID()==Duel.GetTurnCount()
end
function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end